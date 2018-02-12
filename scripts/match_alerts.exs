
defmodule MatchAlerts do
  @moduledoc """
  Usage: mix run scripts/match_alerts.exs [options]
      -h, --help                       Print this message
      -m number, --match number        Match user in database
      -d, --delete                     Delete notifications previously created by script
  """

  import Ecto.Query
  alias AlertProcessor.Repo
  alias AlertProcessor.Model.{Alert, Notification, InformedEntity}

  def run(:help), do: IO.write(@moduledoc)
  def run({:match, number}), do: match(number)
  def run(:delete), do: delete()

  defp match(number) do
    now = DateTime.utc_now()
    start_time = %DateTime{year: now.year, month: now.month, day: now.day, zone_abbr: "EST", hour: 23, minute: 0, second: 0,
                      microsecond: {0, 0}, utc_offset: -5, std_offset: 0, time_zone: "America/New_York"}
    end_time = %DateTime{year: now.year, month: now.month, day: now.day, zone_abbr: "EST", hour: 23, minute: 59, second: 0,
                         microsecond: {0, 0}, utc_offset: -5, std_offset: 0, time_zone: "America/New_York"}

    matching_alert = %Alert{
      active_period: [%{end: end_time, start: start_time}],
      created_at: now,
      duration_certainty: :known,
      effect_name: "Service Change",
      header: "Header Text",
      id: "1",
      informed_entities: [%InformedEntity{
        activities: ["BOARD"], direction_id: 0, inserted_at: nil, route: "Red", route_type: 1, stop: "place-alfcl"}],
      last_push_notification: now,
      recurrence: nil,
      service_effect: "Service Effect",
      severity: :moderate,
      timeframe: nil,
      url: nil}

    non_matching_alert = %Alert{
      active_period: [%{end: end_time, start: start_time}],
      created_at: now,
      duration_certainty: :known,
      effect_name: "Service Change",
      header: "Header Text",
      id: "2",
      informed_entities: [%InformedEntity{
        activities: ["BOARD"], direction_id: 0, inserted_at: nil, route: "Blue", route_type: 1, stop: "place-wondl"}],
      last_push_notification: now,
      recurrence: nil,
      service_effect: "Service Effect",
      severity: :moderate,
      timeframe: nil,
      url: nil
    }

    IO.puts "Begin Matching"
    start_notification_count = number_of_sent_notifications()
    end_notification_count = start_notification_count + number
    AlertProcessor.SubscriptionFilterEngine.schedule_all_notifications([matching_alert, non_matching_alert])

    IO.puts "Wait for Notification Writes"
    check_sent_notifications(start_notification_count, end_notification_count)

    IO.puts "Re-Match Previously Sent Alert"
    AlertProcessor.SubscriptionFilterEngine.schedule_all_notifications([matching_alert])
  end

  defp check_sent_notifications(original_count, count) do
    current_count = number_of_sent_notifications()
    if current_count - original_count < count do
      :timer.sleep(100)
      check_sent_notifications(original_count, count)
    end
  end

  defp number_of_sent_notifications do
    Repo.one(from n in Notification, select: count("*"))
  end

  defp delete do
    Ecto.Adapters.SQL.query!(AlertProcessor.Repo,
      "DELETE FROM notifications WHERE user_id IN (SELECT id FROM users WHERE email LIKE 'send-alerts-test%')", [],
      [timeout: :infinity])
  end
end

opts = OptionParser.parse(System.argv(),
  switches: [help: :boolean , match: :integer],
  aliases: [h: :help, m: :match, d: :delete])

case opts do
  {[help: true], _, _} -> :help
  {[match: n], _, _} -> {:match, n}
  {[delete: true], _, _} -> :delete
  _ -> :exit
end
|> MatchAlerts.run()
