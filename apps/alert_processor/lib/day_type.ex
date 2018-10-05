defmodule AlertProcessor.DayType do
  @moduledoc """
  Determine the type (weekday vs weekend) of dates and figure out future instances of a type of day.
  """
  @type day_type_test_function :: (Date.t() | tuple -> :boolean)
  @type next_day_of_type_function :: (Date.t() | nil -> Date.t())

  @doc """
  Determine whether a date is a weekday (Monday–Friday).

      iex> ~D[2015-07-06] |> AlertProcessor.DayType.weekday?() # Monday
      true
      iex> ~D[2015-07-05] |> AlertProcessor.DayType.weekday?() # Sunday
      false
      iex> {2015, 7, 6} |> AlertProcessor.DayType.weekday?() # Monday
      true
      iex> {2015, 7, 5} |> AlertProcessor.DayType.weekday?() # Sunday
      false
  """
  @spec weekday?(Date.t() | tuple) :: boolean
  def weekday?(date), do: Calendar.Date.day_of_week(date) < 6

  @doc """
  Determine whether a date is a weekend day (Saturday or Sunday).

      iex> ~D[2015-07-06] |> AlertProcessor.DayType.weekend?() # Monday
      false
      iex> ~D[2015-07-05] |> AlertProcessor.DayType.weekend?() # Sunday
      true
      iex> {2015, 7, 6} |> AlertProcessor.DayType.weekend?() # Monday
      false
      iex> {2015, 7, 5} |> AlertProcessor.DayType.weekend?() # Sunday
      true
  """
  @spec weekend?(Date.t() | tuple) :: boolean
  def weekend?(date), do: not weekday?(date)

  @doc """
  Find the next weekday day (Monday–Friday) starting with either today or a given date (inclusive).

      iex> AlertProcessor.DayType.next_weekday(~D[2015-07-06])
      ~D[2015-07-06]
      iex> AlertProcessor.DayType.next_weekday(~D[2015-07-04])
      ~D[2015-07-06]
  """
  @spec next_weekday(Date.t() | nil) :: Date.t()
  def next_weekday(date \\ today()), do: next_day_of_type(date, &weekday?/1)

  @doc """
  Find the next weekend day (Saturday or Sunday) starting with either today or a given date (inclusive).

      iex> AlertProcessor.DayType.next_weekend_day(~D[2015-07-05])
      ~D[2015-07-05]
      iex> AlertProcessor.DayType.next_weekend_day(~D[2015-07-06])
      ~D[2015-07-11]
  """
  @spec next_weekend_day(Date.t() | nil) :: Date.t()
  def next_weekend_day(date \\ today()), do: next_day_of_type(date, &weekend?/1)

  @doc """
  Find the next Saturday starting with either today or a given date (inclusive).

      iex> AlertProcessor.DayType.next_saturday(~D[2018-08-25])
      ~D[2018-08-25]
      iex> AlertProcessor.DayType.next_saturday(~D[2018-08-26])
      ~D[2018-09-01]
  """
  @spec next_saturday(Date.t() | nil) :: Date.t()
  def next_saturday(date \\ today()), do: next_day_of_type(date, &Calendar.Date.saturday?/1)

  @doc """
  Takes the first `amount` weekdays (Monday–Friday) starting with either today or a given date (inclusive).

    iex> AlertProcessor.DayType.take_weekdays(4, ~D[2015-07-09])
    [~D[2015-07-09], ~D[2015-07-10], ~D[2015-07-13], ~D[2015-07-14]]
    iex> AlertProcessor.DayType.take_weekdays(2, ~D[2018-08-25])
    [~D[2018-08-27], ~D[2018-08-28]]
  """
  @spec take_weekdays(non_neg_integer, Date.t() | nil) :: [Date.t()]
  def take_weekdays(amount, date \\ today()),
    do: take_days_using_next_function(amount, date, &next_weekday/1)

  @doc """
  Takes the first `amount` weekend day (Saturday or Sunday) starting with either today or a given date (inclusive).

    iex> AlertProcessor.DayType.take_weekend_days(4, ~D[2015-07-05])
    [~D[2015-07-05], ~D[2015-07-11], ~D[2015-07-12], ~D[2015-07-18]]
    iex> AlertProcessor.DayType.take_weekend_days(3, ~D[2018-08-23])
    [~D[2018-08-25], ~D[2018-08-26], ~D[2018-09-01]]
  """
  @spec take_weekend_days(non_neg_integer, Date.t() | nil) :: [Date.t()]
  def take_weekend_days(amount, date \\ today()),
    do: take_days_using_next_function(amount, date, &next_weekend_day/1)

  @doc """
  Takes the first `amount` weekend day (Saturday or Sunday) starting with either today or a given date (inclusive).

    iex> AlertProcessor.DayType.take_saturdays(3, ~D[2015-07-04])
    [~D[2015-07-04], ~D[2015-07-11], ~D[2015-07-18]]
    iex> AlertProcessor.DayType.take_saturdays(3, ~D[2018-08-23])
    [~D[2018-08-25], ~D[2018-09-01], ~D[2018-09-08]]
  """
  @spec take_saturdays(non_neg_integer, Date.t() | nil) :: [Date.t()]
  def take_saturdays(amount, date \\ today()),
    do: take_days_using_next_function(amount, date, &next_saturday/1)

  @spec today() :: Date.t()
  defp today, do: Calendar.Date.today!("America/New_York")

  @spec next_day(Date.t()) :: Date.t()
  defp next_day(date) do
    with {:ok, next_date} = Calendar.Date.add(date, 1), do: next_date
  end

  @spec next_day_of_type(Date.t(), day_type_test_function) :: Date.t()
  defp next_day_of_type(date, day_type_test_function) do
    date
    |> Stream.unfold(&{&1, next_day(&1)})
    |> Enum.find(day_type_test_function)
  end

  @spec take_days_using_next_function(non_neg_integer, Date.t(), next_day_of_type_function) :: [
          Date.t()
        ]
  defp take_days_using_next_function(amount, date, next_function) do
    date
    |> next_function.()
    |> Stream.unfold(&{&1, &1 |> next_day() |> next_function.()})
    |> Enum.take(amount)
  end
end
