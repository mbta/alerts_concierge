defmodule AlertProcessor.InformedEntityFilter do
  @moduledoc """
  Filter users based on informed entity records tied to subscriptions.
  """

  alias AlertProcessor.Model.{Alert, InformedEntity, Subscription}

  @doc """
  filter/1 takes a tuple including a subquery which represents the
  remaining subscriptions to be considered and
  an alert and returns the now remaining subscriptions to be considered
  in the form of an ecto queryable
  which have matched based on informed entities and
  an alert to pass through to the next filter. Otherwise the flow is
  shortcircuited if the user id list provided is missing or empty.
  """
  @spec filter([Subscription.t], Keyword.t) :: [Subscription.t]
  def filter(subscriptions, [alert: alert]) do
    do_filter(subscriptions, alert)
  end

  defp do_filter(subscriptions, %Alert{informed_entities: informed_entities}) do
    alert_ies = Enum.map(
      informed_entities,
      fn(ie) ->
        ie_struct = Map.merge(%InformedEntity{}, ie)
        Map.take(ie_struct, InformedEntity.queryable_fields)
      end)

    Enum.filter(subscriptions, fn(sub) ->
      sub.informed_entities
      |> Enum.any?(
        fn(sub_ie) ->
          ie = Map.take(sub_ie, InformedEntity.queryable_fields)
          Enum.any?(alert_ies, & entity_match?(&1, ie))
        end)
    end)
  end

  defp entity_match?(%{trip: trip_id} = alert, %{trip: subscription_trip_id} = subscription) when not is_nil(trip_id) do
    trip_id == subscription_trip_id and
    alert.route_type == subscription.route_type and
    alert.route == subscription.route and
    alert.direction_id == subscription.direction_id and
    activity_overlap?(alert.activities, subscription.activities)
  end
  defp entity_match?(%{facility_type: ft, route: route, stop: stop, activities: activities},
    %{facility_type: sub_ft, route: sub_route, activities: sub_activities, stop: sub_stop}) when not is_nil(ft) and not is_nil(sub_ft) do

    if is_nil(sub_stop) do
      route == sub_route && activity_overlap?(activities, sub_activities)
    else
      stop == sub_stop && activity_overlap?(activities, sub_activities)
    end
  end
  defp entity_match?(alert_ie, subscription_ie) do
    alert_activities = alert_ie.activities
    subscription_activities = subscription_ie.activities

    activity_overlap?(subscription_activities, alert_activities) && Map.put(alert_ie, :activities, nil) == Map.put(subscription_ie, :activities, nil)
  end

  defp activity_overlap?(activities, other_activities) do
    Enum.any?(activities, &Enum.member?(other_activities, &1))
  end
end
