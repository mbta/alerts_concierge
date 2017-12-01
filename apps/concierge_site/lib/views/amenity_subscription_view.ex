defmodule ConciergeSite.AmenitySubscriptionView do
  use ConciergeSite.Web, :view
  alias AlertProcessor.Model.Subscription
  import ConciergeSite.SubscriptionHelper,
    only: [relevant_days: 1]

  @doc """
  Returns string with ampersand separated list of facilty types for an amenity subscription
  """
  @spec amenity_facility_type(Subscription.t) :: String.t
  def amenity_facility_type(subscription) do
    subscription.informed_entities
    |> Enum.map(&(&1.facility_type))
    |> Enum.uniq
    |> Enum.map(fn(amenity) ->
      amenity
      |> Atom.to_string()
      |> String.replace("_", " ")
      |> String.capitalize()
    end)
    |> AlertProcessor.Helpers.StringHelper.and_join()
  end

  @doc """
  Returns human readable description of amenity schedule
  # of stations, which lines, and days of travel
  Example: 2 stations + Green line, Weekdays
  """
  @spec amenity_schedule(Subscription.t) :: iolist
  def amenity_schedule(subscription) do
    entity_info = Enum.join(pretty_station_count(subscription) ++ lines(subscription), " + ")
    [
      entity_info,
      " on ",
      relevant_days(subscription)
    ]
  end

  defp pretty_station_count(subscription) do
    case count = number_of_stations(subscription) do
      0 -> []
      1 -> ["1 station"]
      _ -> ["#{count} stations"]
    end
  end

  defp number_of_stations(subscription) do
    subscription.informed_entities
    |> Enum.filter(&(!is_nil(&1.stop)))
    |> Enum.map(&(&1.stop))
    |> Enum.uniq
    |> length
  end

  defp lines(subscription) do
    subscription.informed_entities
    |> Enum.filter(&(!is_nil(&1.route)))
    |> Enum.map(&("#{&1.route} Line"))
    |> Enum.uniq
    |> Enum.join(", ")
    |> List.wrap()
    |> Enum.filter(& String.length(&1) > 0)
  end
end
