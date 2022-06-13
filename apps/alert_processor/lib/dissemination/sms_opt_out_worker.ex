defmodule AlertProcessor.SmsOptOutWorker do
  @moduledoc """
  Periodically fetches the list of opted-out phone numbers (those that sent a "STOP" message to
  the number that sends alerts), and disables alerts for the corresponding user accounts.
  """
  use GenServer
  require Logger
  alias AlertProcessor.Aws.AwsClient
  alias AlertProcessor.Helpers.ConfigHelper
  alias AlertProcessor.Lock
  alias AlertProcessor.Model.User

  @type next_token :: String.t() | nil
  @type phone_number :: String.t()

  @doc "Start the server. The first check is done immediately."
  def start_link(opts) do
    GenServer.start_link(__MODULE__, nil, opts)
  end

  @impl GenServer
  def init(_) do
    send(self(), :work)
    {:ok, nil}
  end

  @impl GenServer
  def handle_info(:work, state) do
    process_opt_outs()
    Process.send_after(self(), :work, fetch_interval())
    {:noreply, state}
  end

  @impl GenServer
  def handle_info(_, state), do: {:noreply, state}

  def process_opt_outs do
    Lock.acquire(__MODULE__, fn
      :ok ->
        do_process_opt_outs()

      :error ->
        Logger.warn("SmsOptOutWorker event=skipped")
    end)
  end

  defp do_process_opt_outs do
    with {:ok, opted_out_numbers} <- fetch_opted_out_list(nil),
         {:ok, multi_result} <- User.set_sms_opted_out(opted_out_numbers) do
      Logger.info([
        "SmsOptOutWorker event=processed ",
        "numbers=#{length(opted_out_numbers)} updated=#{map_size(multi_result)}"
      ])
    else
      {:error, error} ->
        Logger.warn("SmsOptOutWorker event=fetch_error #{inspect(error)}")

      {:error, _, user, _} ->
        Logger.warn("SmsOptOutWorker event=update_error #{inspect(user)}")
    end
  end

  @spec fetch_opted_out_list(next_token, [phone_number]) :: {:ok, [phone_number]} | {:error, any}
  def fetch_opted_out_list(next_token, opted_out_list \\ []) do
    case next_token |> list_numbers_opted_out_query() |> AwsClient.request() do
      {:ok, %{body: %{next_token: next_token, phone_numbers: phone_numbers}}} ->
        normalized_phone_numbers = Enum.map(phone_numbers, &String.replace_leading(&1, "+1", ""))

        case next_token do
          "" ->
            {:ok, opted_out_list ++ normalized_phone_numbers}

          token ->
            # The underlying API call here has a hard rate limit of 10 requests
            # per second. See: https://docs.aws.amazon.com/general/latest/gr/sns.html
            # Sleep enough that we're slightly under that rate limit
            Process.sleep(200)
            fetch_opted_out_list(token, opted_out_list ++ normalized_phone_numbers)
        end

      {:error, error} ->
        {:error, {length(opted_out_list), error}}
    end
  end

  @spec list_numbers_opted_out_query(next_token) :: ExAws.Operation.Query.t()
  defp list_numbers_opted_out_query(nil), do: ExAws.SNS.list_phone_numbers_opted_out()
  defp list_numbers_opted_out_query(token), do: ExAws.SNS.list_phone_numbers_opted_out(token)

  defp fetch_interval do
    ConfigHelper.get_int(:opted_out_list_fetch_interval)
  end
end
