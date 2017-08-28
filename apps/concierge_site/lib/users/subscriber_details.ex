defmodule ConciergeSite.SubscriberDetails do
  alias AlertProcessor.{Helpers.DateTimeHelper, Model.Notification, Model.Subscription, Model.User, Repo}
  alias ConciergeSite.TimeHelper
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
    |> Enum.group_by(fn({date, _, _}) -> date end, fn({_, time, change}) -> {time, change} end)
    |> Enum.to_list()
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
        {date, time} = date_and_time_values(inserted_at)
        originator = originating_user_email_map[id] || "Unknown"
      {[{date, time, originator <> " created " <> rest}], Map.put(acc, item_id, item_changes)}
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
        {date, time} = date_and_time_values(inserted_at)
        originator = originating_user_email_map[id] || "Unknown"
      {[{date, time, originator <> " updated " <> message <> " for subscription " <> item_id}], Map.put(acc, item_id, Map.merge(old_version, item_changes))}
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
        {date, time} = date_and_time_values(inserted_at)
        originator = originating_user_email_map[id] || "Unknown"
      {[{date, time, originator <> " deleted " <> rest}], Map.delete(acc, item_id)}
  end
  defp changelog_item(%{
    inserted_at: inserted_at,
    event: "insert",
    item_changes: item_changes,
    item_id: item_id,
    item_type: "User"
    }, acc, _) do
      {date, time} = date_and_time_values(inserted_at)
      {[{date, time, "Account created"}], Map.put(acc, item_id, item_changes)}
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
      {date, time} = date_and_time_values(inserted_at)
      originator = originating_user_email_map[id] || "Unknown"
      {[{date, time, originator <> " updated " <> message}], Map.put(acc, item_id, new_state)}
  end
  defp changelog_item(%{
    inserted_at: inserted_at,
    event: "insert",
    originator_id: id,
    item_changes: %{"trip" => trip, "subscription_id" => subscription_id},
    item_type: "InformedEntity"
    }, acc, originating_user_email_map) when is_binary(trip) do
      {date, time} = date_and_time_values(inserted_at)
      originator = originating_user_email_map[id] || "Unknown"
      {[{date, time, originator <> " added trip " <> trip <> " to subscription " <> subscription_id}], acc}
  end
  defp changelog_item(%{
    inserted_at: inserted_at,
    event: "insert",
    originator_id: id,
    item_changes: %{"stop" => stop, "subscription_id" => subscription_id},
    item_type: "InformedEntity"
    }, acc, originating_user_email_map) when is_binary(stop) do
      {date, time} = date_and_time_values(inserted_at)
      originator = originating_user_email_map[id] || "Unknown"
      {[{date, time, originator <> " added stop " <> stop <> " to subscription " <> subscription_id}], acc}
  end
  defp changelog_item(%{
    inserted_at: inserted_at,
    event: "delete",
    originator_id: id,
    item_changes: %{"trip" => trip, "subscription_id" => subscription_id},
    item_type: "InformedEntity"
    }, acc, originating_user_email_map) when is_binary(trip) do
      {date, time} = date_and_time_values(inserted_at)
      originator = originating_user_email_map[id] || "Unknown"
      {[{date, time, originator <> " removed trip " <> trip <> " from subscription " <> subscription_id}], acc}
  end
  defp changelog_item(%{
    inserted_at: inserted_at,
    event: "delete",
    originator_id: id,
    item_changes: %{"stop" => stop, "subscription_id" => subscription_id},
    item_type: "InformedEntity"
    }, acc, originating_user_email_map) when is_binary(stop) do
      {date, time} = date_and_time_values(inserted_at)
      originator = originating_user_email_map[id] || "Unknown"
      {[{date, time, originator <> " removed stop " <> stop <> " from subscription " <> subscription_id}], acc}
  end
  defp changelog_item(%{item_type: "InformedEntity"}, acc, _) do
    {[], acc}
  end

  def notification_timeline(user) do
    user
    |> Notification.sent_to_user()
    |> Enum.map(fn(%Notification{service_effect: service_effect, header: header, description: description, inserted_at: inserted_at} = notification) ->
         {date, time} = date_and_time_values(inserted_at)
         {date, time, [
           notification_type(notification),
           " sent to: ",
           notification_contact(notification),
           " -- ",
           service_effect,
           " ",
           header,
           " ",
           description
          ]}
       end)
    |> Enum.group_by(fn({date, _, _}) -> date end, fn({_, time, message}) -> {time, message} end)
    |> Enum.to_list()
  end

  defp notification_type(%Notification{phone_number: nil}), do: "Email"
  defp notification_type(%Notification{}), do: "SMS"

  defp notification_contact(%Notification{phone_number: nil, email: email}), do: email
  defp notification_contact(%Notification{phone_number: phone_number}), do: phone_number

  defp date_and_time_values(inserted_at) do
    date = DateTimeHelper.format_date(inserted_at)
    time = inserted_at |> NaiveDateTime.to_time() |> TimeHelper.format_time()
    {date, time}
  end
end
