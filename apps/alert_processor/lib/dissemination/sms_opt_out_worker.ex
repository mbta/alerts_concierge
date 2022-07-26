defmodule AlertProcessor.SmsOptOutWorker do
  @moduledoc """
  Periodically fetches the list of opted-out phone numbers (those that sent a "STOP" message to
  the number that sends alerts), and disables alerts for the corresponding user accounts.
  """
  import Ecto.Query

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
        try do
          do_process_opt_outs()
        rescue
          e -> Logger.error("SmsOptOutWorker event=error #{inspect(e)}")
        end

      :error ->
        Logger.warn("SmsOptOutWorker event=skipped")
    end)
  end

  defp fetch_phone_numbers() do
    User
    |> select([u], u.phone_number)
    |> where([u], not is_nil(u.phone_number))
    |> distinct(true)
    |> AlertProcessor.Repo.all()
  end

  defp format_phone_number(phone_number) do
    "+1#{phone_number}"
  end

  defp check_opted_out(phone_number) do
    resp =
      phone_number
      |> format_phone_number()
      |> ExAws.SNS.check_if_phone_number_is_opted_out()
      |> AwsClient.request()

    case resp do
      {:ok, %{body: %{is_opted_out: is_opted_out}}} -> {:ok, is_opted_out}
      {:error, e} -> {:error, e}
    end
  end

  defp collect_opted_out(phone_numbers) do
    Enum.reduce(phone_numbers, {[], 0, 0}, fn number, {opted_out, untouched_count, error_count} ->
      res =
        case check_opted_out(number) do
          {:ok, true} ->
            {[number | opted_out], untouched_count, error_count}

          {:ok, _} ->
            {opted_out, untouched_count + 1, error_count}

          {:error, e} ->
            Logger.warn(["SmsOptOutWorker event=aws_error #{inspect(e)}"])
            {opted_out, untouched_count, error_count + 1}
        end

      # From https://docs.aws.amazon.com/general/latest/gr/sns.html
      # The rate limit for CheckIfPhoneNumberIsOptedOut is 50 requests /
      # second. Sleep so that we're just under that limit.
      Process.sleep(25)

      res
    end)
  end

  defp do_process_opt_outs do
    Logger.info("SmsOptOutWorker event=starting")
    phone_numbers = fetch_phone_numbers()
    {opted_out_numbers, untouched_count, error_count} = collect_opted_out(phone_numbers)

    case User.set_sms_opted_out(opted_out_numbers) do
      {:ok, multi_result} ->
        Logger.info([
          "SmsOptOutWorker event=processed ",
          "opted_out=#{map_size(multi_result)} untouched=#{untouched_count} errors=#{error_count}"
        ])

      {:error, _, user, _} ->
        Logger.warn(["SmsOptOutWorker event=update_error #{inspect(user)}"])
    end

    {opted_out_numbers, untouched_count, error_count}
  end

  defp fetch_interval do
    ConfigHelper.get_int(:opted_out_list_fetch_interval)
  end
end
