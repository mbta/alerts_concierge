defmodule ConciergeSite.AmenitySubscriptionView do
  use ConciergeSite.Web, :view
  import ConciergeSite.SubscriptionHelper,
    only: [relevant_days: 1]

  def stringify(params) when is_list(params) do
    Enum.join(params, ",")
  end
  def stringify(p), do: p

  @doc """
  Returns ampersand separated list of facilty types for an amenity subscription
  """
  @spec amenity_facility_type(Subscription.t) :: iolist
  def amenity_facility_type(subscription) do
    subscription.informed_entities
    |> Enum.map(&(&1.facility_type))
    |> Enum.uniq
    |> Enum.map(fn(amenity) ->
      amenity
      |> Atom.to_string()
      |> String.capitalize()
    end)
    |> Enum.join(" & ")
  end

  @doc """
  Returns human readable description of amenity schedule
  # of stations, which lines, and days of travel
  Example: 2 stations + Green line, Weekdays
  """
  @spec amenity_schedule(Subscription.t) :: iolist
  def amenity_schedule(subscription) do
    [
      pretty_station_count(subscription),
      lines(subscription),
      " on ",
      relevant_days(subscription)
    ]
  end

  defp pretty_station_count(subscription) do
    case count = number_of_stations(subscription) do
      1 -> "#{count} station + "
      _ -> "#{count} stations + "
    end
  end

  defp number_of_stations(subscription) do
    subscription.informed_entities
    |> Enum.filter_map(
      &(!is_nil(&1.stop)),
      &(&1.stop)
    )
    |> length
  end

  defp lines(subscription) do
    subscription.informed_entities
    |> Enum.filter_map(
      &(!is_nil(&1.route)),
      &("#{&1.route} Line")
    )
    |> Enum.uniq
    |> Enum.join(", ")
  end
end
