defmodule AlertProcessor.AlertFilters do
  alias AlertProcessor.Model.Alert
  @type duration_type :: :older | :recent | :anytime
  @recent_threshold 3_600 # 60 * 60, 1 hour

  @spec filter_by_duration_type([Alert.t], duration_type, DateTime.t | nil) :: [Alert.t]
  def filter_by_duration_type(alerts, duration_type, now \\ DateTime.utc_now())
  def filter_by_duration_type(alerts, :anytime, _), do: alerts
  def filter_by_duration_type(alerts, :older, now) do
    Enum.filter(alerts, fn(%{last_push_notification: last_push_notification}) ->
      @recent_threshold <= DateTime.diff(now, last_push_notification, :second)
    end)
  end
  def filter_by_duration_type(alerts, :recent, now) do
    Enum.filter(alerts, fn(%{last_push_notification: last_push_notification}) ->
      @recent_threshold >= DateTime.diff(now, last_push_notification, :second)
    end)
  end
end