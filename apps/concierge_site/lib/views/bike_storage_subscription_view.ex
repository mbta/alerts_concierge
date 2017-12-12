defmodule ConciergeSite.BikeStorageSubscriptionView do
  use ConciergeSite.Web, :view
  alias AlertProcessor.Model.Subscription
  import ConciergeSite.SubscriptionHelper,
    only: [relevant_days: 1]

  @doc """
  Returns string with ampersand separated list of facilty types for an bike_storage subscription
  """
  @spec bike_storage_facility_type(Subscription.t) :: String.t
  def bike_storage_facility_type(subscription) do
    subscription.informed_entities
    |> Enum.map(&(&1.facility_type))
    |> Enum.uniq
    |> Enum.map(fn(bike_storage) ->
      bike_storage
      |> Atom.to_string()
      |> String.replace("_", " ")
      |> String.capitalize()
    end)
    |> Enum.sort
    |> AlertProcessor.Helpers.StringHelper.and_join()
  end

  @doc """
  Returns human readable description of bike_storage schedule
  # of stations, which lines, and days of travel
  Example: 2 stations + Green line, Weekdays
  """
  @spec bike_storage_schedule(Subscription.t) :: iolist
  def bike_storage_schedule(subscription) do
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
