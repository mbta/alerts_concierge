defmodule AlertProcessor.AlertFilters do
  @moduledoc """
  Filter alerts by duration type
  """
  alias AlertProcessor.Model.Alert
  @type duration_type :: :older | :oldest | :recent | :anytime
  # 60 * 60, 1 hour
  @recent_threshold 3_600
  # 60 * 60 * 24, 24 hours
  @oldest_theshold 86_400

  @spec filter_by_duration_type([Alert.t()], duration_type, DateTime.t() | nil) :: [Alert.t()]
  def filter_by_duration_type(alerts, duration_type, now \\ DateTime.utc_now())
  def filter_by_duration_type(alerts, :anytime, _), do: alerts

  def filter_by_duration_type(alerts, :older, now) do
    Enum.filter(alerts, fn %{last_push_notification: last_push_notification} ->
      @recent_threshold <= DateTime.diff(now, last_push_notification, :second) &&
        @oldest_theshold >= DateTime.diff(now, last_push_notification, :second)
    end)
  end

  def filter_by_duration_type(alerts, :oldest, now) do
    Enum.filter(alerts, fn %{last_push_notification: last_push_notification} ->
      @oldest_theshold <= DateTime.diff(now, last_push_notification, :second)
    end)
  end

  def filter_by_duration_type(alerts, :recent, now) do
    Enum.filter(alerts, fn %{last_push_notification: last_push_notification} ->
      @recent_threshold >= DateTime.diff(now, last_push_notification, :second)
    end)
  end
end
