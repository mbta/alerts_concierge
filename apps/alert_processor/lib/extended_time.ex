defmodule AlertProcessor.ExtendedTime do
  @moduledoc """
  ExtendedTime is for saving schedule-related times while accounting for fact that a "day" of a schedule stretches into the next actual day. I.E. a trip that leaves at 11:30pm on Jan 1 and another that leaves at 12:30am on Jan 2 are both counted as part of the Jan 1 schedule, but when you are naively sorting times separated from dates the 12:30am trip will incorrectly be sorted before the 11:30pm trip. To account for this we include a "relative_day" concept where 1 represents the base day and 2 represents the next day the schedule extends into.
  """
  alias AlertProcessor.ExtendedTime

  defstruct [
    :relative_day,
    :time
  ]

  @type id :: String.t()
  @type t :: %__MODULE__{
          relative_day: 1 | 2,
          time: Time.t()
        }

  @doc """
  Builds an ExtendedTime struct by comparing a NaiveDateTime with a base date.

  ## Examples

      iex> AlertProcessor.ExtendedTime.new(~N[2018-01-02 00:30:00], ~D[2018-01-01])
      {:ok, %AlertProcessor.ExtendedTime{relative_day: 2, time: ~T[00:30:00]}}
  """
  @spec new(NaiveDateTime.t(), Date.t()) :: {:ok, t}
  def new(%NaiveDateTime{} = date_time, %Date{} = base_date) do
    relative_day =
      if Date.compare(NaiveDateTime.to_date(date_time), base_date) == :eq, do: 1, else: 2

    extendedday_time = %ExtendedTime{
      relative_day: relative_day,
      time: NaiveDateTime.to_time(date_time)
    }

    {:ok, extendedday_time}
  end

  @doc """
  Compares two ExtendedTime structs.

  Returns :gt if first date is later than the second and :lt for vice versa. If the two dates are equal :eq is returned.

  ## Examples

      iex> {:ok, x} = AlertProcessor.ExtendedTime.new(~N[2018-01-01 23:00:00], ~D[2018-01-01])
      iex> {:ok, y} = AlertProcessor.ExtendedTime.new(~N[2018-01-01 23:30:00], ~D[2018-01-01])
      iex> {:ok, z} = AlertProcessor.ExtendedTime.new(~N[2018-01-02 00:30:00], ~D[2018-01-01])
      iex> AlertProcessor.ExtendedTime.compare(x, y)
      :lt
      iex> AlertProcessor.ExtendedTime.compare(y, x)
      :gt
      iex> AlertProcessor.ExtendedTime.compare(y, z)
      :lt
      iex> AlertProcessor.ExtendedTime.compare(z, y)
      :gt
      iex> AlertProcessor.ExtendedTime.compare(z, z)
      :eq
  """
  @spec compare(t, t) :: :lt | :eq | :gt
  def compare(%ExtendedTime{relative_day: relative_day_a}, %ExtendedTime{
        relative_day: relative_day_b
      })
      when relative_day_a < relative_day_b,
      do: :lt

  def compare(%ExtendedTime{relative_day: relative_day_a}, %ExtendedTime{
        relative_day: relative_day_b
      })
      when relative_day_a > relative_day_b,
      do: :gt

  def compare(%ExtendedTime{time: time_a}, %ExtendedTime{time: time_b}),
    do: Time.compare(time_a, time_b)
end
