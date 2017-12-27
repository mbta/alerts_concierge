defmodule AlertProcessor.SmsOptOutWorker do
  @moduledoc """
  Module for periodically fetching opted out phone number list
  from aws sns service which represents the list of people who have
  replied 'STOP', 'UNSUBSCRIBE', etc to the sms number which is
  sending alerts.
  """
  use GenServer
  require Logger
  alias AlertProcessor.Aws.AwsClient
  alias AlertProcessor.Model.User
  alias AlertProcessor.HoldingQueue
  alias AlertProcessor.Helpers.ConfigHelper

  @type phone_number :: String.t

  @doc false
  def start_link(opts \\ [name: __MODULE__]) do
    GenServer.start_link(__MODULE__, nil, opts)
  end

  @doc """
  Initialize GenServer and schedule recurring opted out list fetching
  """
  def init(_) do
    schedule_work()
    {:ok, []}
  end

  @doc """
  fetch opted out list, process and reschedule next occurrence
  """
  def handle_info(:work, state) do
    opted_out_phone_numbers = do_work(state)
    schedule_work()
    {:noreply, opted_out_phone_numbers}
  end

  defp schedule_work do
    Process.send_after(self(), :work, fetch_interval())
  end

  defp fetch_interval do
    ConfigHelper.get_int(:opted_out_list_fetch_interval)
  end

  @spec do_work([phone_number]) :: [phone_number]
  defp do_work(state) do
    with opted_out_phone_numbers <- fetch_opted_out_list(nil),
      {:ok, new_opted_out_numbers} <- get_new_opted_out_numbers(state, opted_out_phone_numbers),
      {:ok, user_ids} <- get_opted_out_user_ids(new_opted_out_numbers) do
      update_users_opted_out(user_ids)
      opted_out_phone_numbers
    else
      _ -> state
    end
  end

  @spec fetch_opted_out_list(String.t | nil, [phone_number]) :: [phone_number]
  defp fetch_opted_out_list(next_token, opted_out_list \\ []) do
    {:ok, %{body: %{phone_numbers: phone_numbers} = body}} =
      next_token
      |> list_phone_numbers_opted_out_query()
      |> AwsClient.request()

    normalized_phone_numbers = Enum.map(phone_numbers, &String.replace_leading(&1, "+1", ""))

    case body[:next_token] do
      nil -> opted_out_list ++ normalized_phone_numbers
      nt -> fetch_opted_out_list(nt, opted_out_list ++ normalized_phone_numbers)
    end
  end

  @spec list_phone_numbers_opted_out_query(String.t | nil) :: ExAws.Operation.Query.t
  defp list_phone_numbers_opted_out_query(next_token) do
    case next_token do
      nil -> ExAws.SNS.list_phone_numbers_opted_out()
      _ -> ExAws.SNS.list_phone_numbers_opted_out(next_token)
    end
  end

  @spec get_new_opted_out_numbers([phone_number], [phone_number]) :: {:ok, [phone_number]} | :error
  defp get_new_opted_out_numbers(current_state, opted_out_phone_numbers) do
    case opted_out_phone_numbers -- current_state do
      [] ->
        :error
      new_opted_out_numbers ->
        Logger.info("New opted out numbers: #{inspect(new_opted_out_numbers)}")
        {:ok, new_opted_out_numbers}
    end
  end

  @spec get_opted_out_user_ids([phone_number]) :: [User.id] | :error
  defp get_opted_out_user_ids(new_opted_out_numbers) do
    case User.ids_by_phone_numbers(new_opted_out_numbers) do
      [] -> :error
      user_ids -> {:ok, user_ids}
    end
  end

  @spec update_users_opted_out([User.id]) :: [User.id]
  defp update_users_opted_out(user_ids) do
    User.remove_users_phone_number(user_ids, "sms-opt-out")
    Enum.map(user_ids, &HoldingQueue.remove_user_notifications/1)
  end
end
