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
    SystemMetrics.Tracer.trace(fn() ->
      do_filter(subscriptions, alert)
    end, "informed_entity_filter")
  end

  defp do_filter(subscriptions, %Alert{informed_entities: informed_entities}) do
    normal_subscriptions = Enum.filter(subscriptions, fn(sub) ->
      alert_ies = Enum.map(
        informed_entities,
        fn(ie) ->
          ie_struct = Map.merge(%InformedEntity{}, ie)
          Map.take(ie_struct, InformedEntity.queryable_fields)
        end)

      sub.informed_entities
      |> Enum.map(
        fn(sub_ie) ->
          ie = Map.take(sub_ie, InformedEntity.queryable_fields)
          Enum.any?(alert_ies, & entity_match?(&1, ie))
        end)
      |> Enum.any?
    end)

    admin_subscriptions = admin_subscriptions(subscriptions, informed_entities)

    normal_subscriptions
    |> Kernel.++(admin_subscriptions)
    |> Enum.uniq
  end

  defp entity_match?(%{trip: trip_id}, %{trip: subscription_trip_id}) when not is_nil(trip_id) do
    trip_id == subscription_trip_id
  end
  defp entity_match?(alert_ie, subscription_ie) do
    alert_activities = alert_ie.activities
    subscription_activities = subscription_ie.activities

    Enum.any?(subscription_activities, &Enum.member?(alert_activities, &1)) && Map.put(alert_ie, :activities, nil) == Map.put(subscription_ie, :activities, nil)
  end

  defp admin_subscriptions(subscriptions, informed_entities) do
    route_types =
      informed_entities
      |> Enum.filter(&Map.has_key?(&1, :route_type))
      |> Enum.map(&Subscription.subscription_type_from_route_type(Map.get(&1, :route_type)))

    case route_types do
      [] ->
        []
      _ ->
        subscriptions
        |> Enum.filter(fn(sub) ->
          sub.user.role == "application_administration" &&
          Enum.member?(route_types, Atom.to_string(sub.type)) &&
          length(sub.informed_entities) == 0
        end)
    end
  end
end
