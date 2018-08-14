defmodule ConciergeSite.TripReviewCardHelper do
  import Phoenix.HTML.Tag, only: [content_tag: 2, content_tag: 3]
  alias AlertProcessor.Model.{Subscription, Trip}
  alias AlertProcessor.ServiceInfoCache
  alias ConciergeSite.{IconViewHelper, RouteHelper}

  @doc """
  Render a trip review card for a trip
  """
  @spec render(Trip.t()) :: Phoenix.HTML.safe()
  def render(%Trip{subscriptions: subscriptions, roundtrip: roundtrip?}) do
    subscriptions
    |> RouteHelper.collapse_duplicate_green_legs()
    |> Enum.sort(&(&1.rank <= &2.rank))
    |> row(roundtrip?)
  end

  @spec render([Subscription.t()]) :: Phoenix.HTML.safe()
  def render(subscriptions),
    do: row(subscriptions, includes_return_trip_subscriptions(subscriptions))

  @spec row([Subscription.t()], boolean) :: Phoenix.HTML.safe()
  defp row(subscriptions, roundtrip?) do
    content_tag :div, class: "trip-review row" do
      row_content(subscriptions, roundtrip?)
    end
  end

  @spec row_content([Subscription.t()], boolean) :: Phoenix.HTML.safe()
  defp row_content(subscriptions, _roundtrip? = false), do: one_way_trip(subscriptions)

  defp row_content(subscriptions, _roundtrip? = true),
    do: subscriptions |> split_round_trip_subscriptions() |> round_trip()

  @spec one_way_trip([Subscription.t()]) :: Phoenix.HTML.safe()
  defp one_way_trip(subscriptions) do
    content_tag :div, class: "trip-review--trip col-md-6" do
      [
        content_tag(:h3, "My Trip"),
        card(subscriptions)
      ]
    end
  end

  @spec round_trip({[Subscription.t()], [Subscription.t()]}) :: [Phoenix.HTML.safe()]
  defp round_trip({initial_trip_subscriptions, return_trip_subscriptions}) do
    [
      content_tag :div, class: "trip-review--trip col-md-6" do
        [
          content_tag(:h3, "First trip"),
          card(initial_trip_subscriptions)
        ]
      end,
      content_tag :div, class: "trip-review--trip col-md-6" do
        [
          content_tag(:h3, "Return trip"),
          return_trip_subscriptions |> Enum.reverse() |> card()
        ]
      end
    ]
  end

  @spec card([Subscription.t()]) :: Phoenix.HTML.safe()
  defp card(subscriptions) do
    content_tag :div, class: "card trip-review--card" do
      for subscription <- Trip.nested_subscriptions(subscriptions), do: leg(subscription)
    end
  end

  @spec leg(Subscription.t()) :: Phoenix.HTML.safe()
  defp leg(%Subscription{} = subscription) do
    content_tag :div, class: "trip-review--trip-leg" do
      [
        routes(subscription),
        route_description(subscription)
      ]
    end
  end

  @spec routes(Subscription.t()) :: Phoenix.HTML.safe()
  defp routes(%{child_subscriptions: nil} = subscription) do
    route(subscription)
  end

  defp routes(%{child_subscriptions: child_subscriptions} = subscription) do
    [route(subscription)] ++
      for child_subscription <- child_subscriptions, do: route(child_subscription)
  end

  @spec route(Subscription.t()) :: Phoenix.HTML.safe()
  defp route(%Subscription{type: type, route: route}) do
    content_tag :div, class: "trip-review--route-container" do
      [
        content_tag :span, class: "trip-review--route-icon" do
          IconViewHelper.icon_for_route(type, route)
        end,
        content_tag :span, class: "trip-review--route" do
          RouteHelper.route_name(route)
        end
      ]
    end
  end

  @spec card(Subscription.t()) :: Phoenix.HTML.safe()
  defp route_description(%Subscription{
         origin: origin,
         destination: destination,
         route: route,
         direction_id: direction_id
       }) do
    case {origin, destination, route, direction_id} do
      {nil, nil, route_id, direction_id} -> headsign(route_id, direction_id)
      {origin_id, destination_id, _, _} -> origin_destination(origin_id, destination_id)
    end
  end

  @spec origin_destination(String.t(), String.t()) :: Phoenix.HTML.safe()
  defp origin_destination(origin_id, destination_id) do
    content_tag :div, class: "trip-review--origin-destination" do
      "#{RouteHelper.stop_name(origin_id)} — #{RouteHelper.stop_name(destination_id)}"
    end
  end

  @spec headsign(String.t(), non_neg_integer) :: Phoenix.HTML.safe()
  defp headsign(route_id, direction_id) do
    content_tag :div, class: "trip-review--headsign" do
      direction_headsign(route_id, direction_id)
    end
  end

  @spec direction_headsign(String.t(), non_neg_integer) :: [String.t()]
  defp direction_headsign(route_id, direction_id) do
    headsign_default = if direction_id == 0, do: ["Outbound"], else: ["Inbound"]
    {:ok, route} = ServiceInfoCache.get_route(route_id)

    Map.get(route.headsigns, direction_id, headsign_default)
    |> Enum.intersperse(" ● ")
  end

  @spec includes_return_trip_subscriptions([Subscription.t()]) :: boolean
  defp includes_return_trip_subscriptions(subscriptions),
    do: Enum.any?(subscriptions, & &1.return_trip)

  @spec split_round_trip_subscriptions([Subscription.t()]) ::
          {[Subscription.t()], [Subscription.t()]}
  defp split_round_trip_subscriptions(subscriptions),
    do: Enum.split_with(subscriptions, &(not &1.return_trip))
end
