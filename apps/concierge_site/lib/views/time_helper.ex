defmodule ConciergeSite.TimeHelper do
  @moduledoc """
  Time functions for subscription views
  """

  alias Calendar.Time, as: T
  alias Calendar.DateTime, as: DT
  alias Calendar.Strftime
  alias AlertProcessor.Helpers.DateTimeHelper
  alias AlertProcessor.Model.{Subscription, User}

  @doc """
  Returns stringified times to populate a dropdown list of a full day of times at
  fifteen-minute intervals
  """
  def travel_time_options do
    10_800
    |> Stream.iterate(&(&1 + 900))
    |> Stream.map(&(rem(&1, 86_400)))
    |> Stream.map(&T.from_second_in_day/1)
    |> Stream.map((& {Strftime.strftime!(&1, "%I:%M %p"), Strftime.strftime!(&1, "%H:%M:%S")}))
    |> Enum.take(96)
  end

  @doc """
  Takes a time string in format HH:MM:SS and returns HH:MM AM/PM
  """
  def format_time_string(time_string) do
    time_string
    |> String.split(":")
    |> Enum.map(&String.to_integer/1)
    |> List.to_tuple
    |> Time.from_erl!
    |> Strftime.strftime!("%l:%M %p")
  end

  @doc """
  Takes Time.t and returns HH:MMam/pm
  """
  @spec format_time(Time.t) :: String.t
  def format_time(time) do
    {:ok, output} = Strftime.strftime(time, "%l:%M%P")
    output
  end

  @doc """
  Converts a Time.t to a string with the H:M:S format
  """
  @spec time_to_string(Time.t | nil) :: String.t | nil
  def time_to_string(nil), do: nil
  def time_to_string(time), do: Strftime.strftime!(time, "%H:%M:%S")

  @doc """
  Converts a string with the H:M:S format to a Time.t
  """
  @spec string_to_time(String.t | nil) :: String.t | nil
  def string_to_time(nil), do: nil
  def string_to_time(time), do: Time.from_iso8601!(time)

  @doc """
  Converts timestamp into integer value adjusting late night, after
  midnight values into higher than times before midnight.
  """
  @spec normalized_time_value(Time.t | nil) :: integer
  def normalized_time_value(nil), do: 0
  def normalized_time_value(timestamp) do
    stv = DateTimeHelper.seconds_of_day(timestamp)
    if stv < 10_800 do
      stv + 86_400
    else
      stv
    end
  end

  @spec time_shift_zone(Time.t, String.t, String.t) :: Time.t
  def time_shift_zone(time, current_zone, target_timezone) do
    erl_time = T.to_erl(time)
    erl_date = Date.utc_today()

    erl_date
    |> DT.from_date_and_time_and_zone!(erl_time, current_zone)
    |> DT.shift_zone!(target_timezone)
    |> DT.to_time()
  end

  @spec subscription_during_do_not_disturb?(Subscription.t, User.t) :: boolean
  def subscription_during_do_not_disturb?(_, %User{do_not_disturb_start: nil, do_not_disturb_end: nil}), do: false
  def subscription_during_do_not_disturb?(%Subscription{type: :amenity}, _), do: false
  def subscription_during_do_not_disturb?(%Subscription{start_time: sub_start_time, end_time: sub_end_time}, %User{do_not_disturb_start: dnd_start, do_not_disturb_end: dnd_end}) do
    start_time = time_shift_zone(sub_start_time, "Etc/UTC", "America/New_York")
    end_time = time_shift_zone(sub_end_time, "Etc/UTC", "America/New_York")

    if normalized_time_value(dnd_start) > normalized_time_value(dnd_end) do
      normalized_time_value(end_time) > normalized_time_value(dnd_start) || normalized_time_value(dnd_end) > normalized_time_value(start_time)
    else
      !(normalized_time_value(start_time) >= normalized_time_value(dnd_end) || normalized_time_value(dnd_start) >= normalized_time_value(end_time))
    end
  end
end
