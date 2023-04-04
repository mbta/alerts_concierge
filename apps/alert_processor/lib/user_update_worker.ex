defmodule AlertProcessor.UserUpdateWorker do
  @moduledoc """
  Fetch user update message sent from Keycloak via an SQS queue.
  Apply the change to our local record.
  """

  use GenServer

  require Logger

  alias AlertProcessor.Helpers.{ConfigHelper, PhoneNumber}
  alias AlertProcessor.Model.User
  alias ExAws.SQS

  @type message :: %{
          user_update: user_update(),
          receipt_handle: String.t()
        }

  @type user_update :: %{
          required(:user_id) => String.t(),
          required(:updates) => %{
            optional(:email) => String.t(),
            optional(:phone) => String.t()
          }
        }

  # Client

  @spec start_link() :: GenServer.on_start()
  @spec start_link(Keyword.t()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  # Server

  @impl GenServer
  def init(_opts) do
    send(self(), :fetch_message)
    {:ok, nil}
  end

  @impl GenServer
  def handle_info(:fetch_message, state) do
    {:ok, messages} = receive_messages()

    for message <- messages do
      case update_user_record(message.user_update) do
        :ok ->
          # Delete the message from SQS once successfully processed
          Logger.info(
            "Finished processing and deleting SQS message receipt_handle=#{message.receipt_handle}"
          )

          delete_message_fn =
            Application.get_env(:alert_processor, :delete_message_fn, &SQS.delete_message/2)

          request_fn = Application.get_env(:alert_processor, :request_fn, &ExAws.request/2)

          user_update_sqs_queue_url()
          |> delete_message_fn.(message.receipt_handle)
          |> request_fn.(region: sqs_aws_region())

          :ok

        :error ->
          # Leave the message in SQS since it hasn't yet been successfully processed
          :error
      end
    end

    send(self(), :fetch_message)
    {:noreply, state}
  end

  @impl GenServer
  def handle_info(_, state), do: {:noreply, state}

  @spec receive_messages :: {:ok, [message()]}
  defp receive_messages do
    receive_message_fn =
      Application.get_env(:alert_processor, :receive_message_fn, &SQS.receive_message/2)

    request_fn = Application.get_env(:alert_processor, :request_fn, &ExAws.request/2)

    Logger.info("Waiting to receive SQS messages")

    user_update_sqs_queue_url()
    |> receive_message_fn.(wait_time_seconds: 20)
    |> request_fn.(region: sqs_aws_region())
    |> handle_sqs_results()
  end

  @spec user_update_sqs_queue_url :: String.t()
  defp user_update_sqs_queue_url, do: ConfigHelper.get_string(:user_update_sqs_queue_url)

  @spec handle_sqs_results({:ok, term()} | {:error, term()}) :: {:ok, [message()]}
  defp handle_sqs_results(
         {:error,
          {:http_error, http_status,
           %{
             code: code,
             message: message,
             request_id: request_id
           }}}
       ) do
    Logger.error(
      "SQS request HTTP error: http_status=#{http_status} code=#{code}, message=#{message}, request_id=#{request_id}"
    )

    {:ok, []}
  end

  defp handle_sqs_results({:error, error}) do
    Logger.error("SQS request error: error=#{inspect(error)}")
    {:ok, []}
  end

  defp handle_sqs_results({:ok, %{body: %{messages: []}, status_code: 200}}) do
    Logger.info("Received SQS messages, count=0")
    {:ok, []}
  end

  defp handle_sqs_results({:ok, %{body: %{messages: messages}, status_code: 200}})
       when is_list(messages) do
    Logger.info("Received SQS messages, count=#{length(messages)}")
    {:ok, Enum.map(messages, &parse_message/1)}
  end

  @spec parse_message(map()) :: map()
  defp parse_message(%{body: body, receipt_handle: receipt_handle}) do
    user_update =
      body
      |> Poison.decode!()
      |> parse_user_update()

    %{
      user_update: user_update,
      receipt_handle: receipt_handle
    }
  end

  @spec parse_user_update(map()) :: user_update()
  defp parse_user_update(%{"mbtaUuid" => user_id, "updates" => updates}) do
    %{
      user_id: user_id,
      updates: %{
        email: Map.get(updates, "email"),
        phone: updates |> Map.get("phone") |> PhoneNumber.strip_us_country_code()
      }
    }
  end

  @spec update_user_record(user_update()) :: :ok | :error
  # Ignore empty updates. The user changed a property we aren't interested in saving locally.
  defp update_user_record(%{updates: updates}) when updates == %{}, do: :ok

  defp update_user_record(%{user_id: user_id, updates: updates}) do
    case User.get(user_id) do
      nil ->
        # Ignore updates for a user that has not yet logged in to T-Alerts
        :ok

      user ->
        updates =
          Map.filter(
            %{
              "email" => Map.get(updates, :email),
              "phone_number" => Map.get(updates, :phone)
            },
            fn {_key, val} -> !is_nil(val) end
          )

        case User.update_account(user, updates, user) do
          {:ok, _updated_user} ->
            Logger.info("Updated user record user_id=#{user_id}")
            :ok

          {:error, changeset} ->
            Logger.error(
              "Unable to update user record user_id=#{user_id} errors: #{inspect(changeset.errors)}"
            )

            :error
        end
    end
  end

  @spec sqs_aws_region :: String.t()
  defp sqs_aws_region, do: System.get_env("SQS_AWS_REGION", "us-east-1")
end
