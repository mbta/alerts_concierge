defmodule ConciergeSite.UserChangelog do
  alias AlertProcessor.{Model.Subscription, Model.User, Repo}
  alias Calendar.Strftime
  import Ecto.Query

  def changelog(user_id) do
    account_changes = account_changes_by_user_id(user_id)
    originating_user_ids =
      account_changes
      |> Enum.flat_map(fn(%{originator_id: originator_id}) ->
           (originator_id && [originator_id]) || []
         end)
    originating_user_email_map = Repo.all(from u in User, where: u.id in ^originating_user_ids, select: {u.id, u.email}) |> Map.new

    {changelog, _} =
      user_id
      |> account_changes_by_user_id()
      |> Enum.flat_map_reduce(%{}, fn(change, acc) ->
           changelog_item(change, acc, originating_user_email_map)
         end)
    changelog
  end

  defp account_changes_by_user_id(user_id) do
    Repo.all(
      from v in PaperTrail.Version,
      left_join: s in Subscription,
      on: v.item_id == s.id and v.item_type == "Subscription",
      where: s.user_id == ^user_id,
      or_where: fragment("?->>'owner' = ?", v.meta, ^user_id),
      or_where: v.item_id == ^user_id,
      order_by: [asc: v.inserted_at]
    )
  end

  defp changelog_item(%{
    inserted_at: inserted_at,
    event: "insert",
    originator_id: id,
    item_changes: item_changes,
    item_id: item_id,
    item_type: "Subscription"
    }, acc, originating_user_email_map) do
      rest =
        case item_changes do
          %{"type" => "amenity"} -> "amenity subscription " <> item_id
          %{"type" => "subway", "origin" => origin, "destination" => destination} -> "subway subscription " <> item_id <> " between " <> origin <> " and " <> destination
          %{"type" => "commuter_rail", "origin" => origin, "destination" => destination} -> "commuter_rail subscription " <> item_id <> " between " <> origin <> " and " <> destination
          %{"type" => "ferry", "origin" => origin, "destination" => destination} -> "ferry subscription " <> item_id <> " between " <> origin <> " and " <> destination
          %{"type" => "bus"} -> "bus subscription " <> item_id
        end
      {[originating_user_email_map[id] <> " created " <> rest <> " on " <> Strftime.strftime!(inserted_at, "%F %T")], Map.put(acc, item_id, item_changes)}
  end
  defp changelog_item(%{
    inserted_at: inserted_at,
    event: "update",
    originator_id: id,
    item_changes: item_changes,
    item_id: item_id,
    item_type: "Subscription"
    }, acc, originating_user_email_map) do
      old_version = Map.get(acc, item_id)
      changed_keys = Map.keys(item_changes)
      message =
        changed_keys
        |> Enum.flat_map(fn(changed_key) ->
            old_value = Map.get(old_version, changed_key) || "N/A"
            new_value = Map.get(item_changes, changed_key) || "N/A"
            if old_value == new_value do
              []
            else
              [changed_key <> " from " <> to_string(old_value) <> " to " <> to_string(new_value)]
            end
          end)
        |> Enum.join(", ")
      {[originating_user_email_map[id] <> " updated " <> message <> " for subscription " <> item_id <> " on " <> Strftime.strftime!(inserted_at, "%F %T")], Map.put(acc, item_id, Map.merge(old_version, item_changes))}
  end
  defp changelog_item(%{
    inserted_at: inserted_at,
    event: "delete",
    originator_id: id,
    item_changes: item_changes,
    item_id: item_id,
    item_type: "Subscription"
    }, acc, originating_user_email_map) do
      rest =
        case item_changes do
          %{"type" => "amenity"} -> "amenity subscription " <> item_id
          %{"type" => "subway", "origin" => origin, "destination" => destination} -> "subway subscription " <> item_id <> " between " <> origin <> " and " <> destination
          %{"type" => "commuter_rail", "origin" => origin, "destination" => destination} -> "commuter_rail subscription " <> item_id <> " between " <> origin <> " and " <> destination
          %{"type" => "ferry", "origin" => origin, "destination" => destination} -> "ferry subscription " <> item_id <> " between" <> origin <> " and " <> destination
          %{"type" => "bus"} -> "bus subscription " <> item_id
        end
      {[originating_user_email_map[id] <> " deleted " <> rest <> " on " <> Strftime.strftime!(inserted_at, "%F %T")], Map.delete(acc, item_id)}
  end
  defp changelog_item(%{
    inserted_at: inserted_at,
    event: "insert",
    item_changes: item_changes,
    item_id: item_id,
    item_type: "User"
    }, acc, _) do
      {["Account created on " <> Strftime.strftime!(inserted_at, "%F %T")], Map.put(acc, item_id, item_changes)}
  end
  defp changelog_item(%{
    inserted_at: inserted_at,
    event: "update",
    originator_id: id,
    item_changes: item_changes,
    item_id: item_id,
    item_type: "User"
    }, acc, originating_user_email_map) do
      old_version = Map.get(acc, item_id, %{})
      changed_keys = Map.keys(item_changes)
      message =
        changed_keys
        |> Enum.flat_map(fn(changed_key) ->
            old_value = Map.get(old_version, changed_key) || "N/A"
            new_value = Map.get(item_changes, changed_key) || "N/A"
            if old_value == new_value do
              []
            else
              [changed_key <> " from " <> to_string(old_value) <> " to " <> to_string(new_value)]
            end
          end)
        |> Enum.join(", ")
      new_state = Map.merge(old_version, item_changes)
      {[originating_user_email_map[id] <> " updated " <> message <> " on " <> Strftime.strftime!(inserted_at, "%F %T")], Map.put(acc, item_id, new_state)}
  end
  defp changelog_item(%{
    inserted_at: inserted_at,
    event: "insert",
    originator_id: id,
    item_changes: %{"trip" => trip, "subscription_id" => subscription_id},
    item_type: "InformedEntity"
    }, acc, originating_user_email_map) when is_binary(trip) do
      {[originating_user_email_map[id] <> " added trip " <> trip <> " to subscription " <> subscription_id <> " on " <> Strftime.strftime!(inserted_at, "%F %T")], acc}
  end
  defp changelog_item(%{
    inserted_at: inserted_at,
    event: "insert",
    originator_id: id,
    item_changes: %{"stop" => stop, "subscription_id" => subscription_id},
    item_type: "InformedEntity"
    }, acc, originating_user_email_map) when is_binary(stop) do
      {[originating_user_email_map[id] <> " added stop " <> stop <> " to subscription " <> subscription_id <> " on " <> Strftime.strftime!(inserted_at, "%F %T")], acc}
  end
  defp changelog_item(%{
    inserted_at: inserted_at,
    event: "delete",
    originator_id: id,
    item_changes: %{"trip" => trip, "subscription_id" => subscription_id},
    item_type: "InformedEntity"
    }, acc, originating_user_email_map) when is_binary(trip) do
      {[originating_user_email_map[id] <> " removed trip " <> trip <> " from subscription " <> subscription_id <> " on " <> Strftime.strftime!(inserted_at, "%F %T")], acc}
  end
  defp changelog_item(%{
    inserted_at: inserted_at,
    event: "delete",
    originator_id: id,
    item_changes: %{"stop" => stop, "subscription_id" => subscription_id},
    item_type: "InformedEntity"
    }, acc, originating_user_email_map) when is_binary(stop) do
      {[originating_user_email_map[id] <> " removed stop " <> stop <> " from subscription " <> subscription_id <> " on " <> Strftime.strftime!(inserted_at, "%F %T")], acc}
  end
  defp changelog_item(%{item_type: "InformedEntity"}, acc, _) do
    {[], acc}
  end
end
