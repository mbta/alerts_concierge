defmodule ConciergeSite.AlertFactory do
  @moduledoc """
  Simplify generation of alerts
  """
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  import AlertProcessor.AlertParser, only: [parse_alert: 3]
  alias AlertProcessor.ServiceInfoCache

  @one_day 86_400

  def alert(alert_data) do
    use_cassette "facilities_alerts", custom: true, clear_mock: true, match_requests_on: [:query] do
      with {:ok, facilities_map} <- ServiceInfoCache.get_facility_map() do
        alert_data
        |> ensure_alert_data_keys()
        |> parse_alert(facilities_map, timestamp())
      end
    end
  end

  defp ensure_alert_data_keys(alert_data) do
    base = %{
      "id" => "1",
      "active_period" => [inclusive_active_period()],
      "created_timestamp" => timestamp(),
      "duration_certainty" => "KNOWN",
      "effect_detail" => "SERVICE_CHANGE",
      "header_text" => [%{"translation" => %{"text" => "Header Text", "language" => "en"}}],
      "service_effect_text" => [%{"translation" => %{"text" => "Service Effect", "language" => "en"}}],
      "severity" => inclusive_severity(),
      "last_push_notification_timestamp" => timestamp()}
    Map.merge(base, alert_data)
  end

  defp inclusive_active_period(), do: %{"start" => timestamp(), "end" => timestamp() + (100 * 365 * 24 * 60 * 60)}
  defp inclusive_severity(), do: 9
  def timestamp(), do: 1514782800 # Monday, January 1, 2018 12:00:00 AM GMT-05:00 (EST)

  def alert_time(time), do: timestamp() + (time.hour * 60 * 60) + (time.minute * 60) + time.second

  def active_period(start_time, end_time, :monday) do
    %{"start" => alert_time(start_time), "end" => alert_time(end_time)}
  end
  def active_period(start_time, end_time, :tuesday) do
    %{"start" => alert_time(start_time) + @one_day, "end" => alert_time(end_time) + @one_day}
  end
  def active_period(start_time, end_time, :sunday) do
    %{"start" => alert_time(start_time) + (@one_day * 6), "end" => alert_time(end_time) + (@one_day * 6)}
  end
  def active_period(start_time, end_time, :saturday) do
    %{"start" => alert_time(start_time) + (@one_day * 5), "end" => alert_time(end_time) + (@one_day * 5)}
  end

  def severity_by_priority("high"), do: 7
  def severity_by_priority("medium"), do: 5
  def severity_by_priority("low"), do: 1
end
