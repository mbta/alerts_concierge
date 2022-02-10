defmodule AlertProcessor.AlertFiltersTest do
  @moduledoc false
  use ExUnit.Case, async: true
  alias AlertProcessor.Model.Alert
  alias AlertProcessor.AlertFilters

  @now ~U[2018-01-01 10:00:00Z]

  @recent_alert %Alert{last_push_notification: ~U[2018-01-01 09:30:00Z], header: "recent"}
  @older_alert %Alert{last_push_notification: ~U[2018-01-01 08:30:00Z], header: "old"}
  @oldest_alert %Alert{last_push_notification: ~U[2000-01-01 00:00:00Z], header: "old"}

  @alerts [@older_alert, @recent_alert, @oldest_alert]

  test "match recent alerts" do
    assert [@recent_alert] == AlertFilters.filter_by_duration_type(@alerts, :recent, @now)
  end

  test "match older alerts" do
    assert [@older_alert] == AlertFilters.filter_by_duration_type(@alerts, :older, @now)
  end

  test "match oldest alerts" do
    assert [@oldest_alert] == AlertFilters.filter_by_duration_type(@alerts, :oldest, @now)
  end

  test "match all alerts" do
    assert [@older_alert, @recent_alert, @oldest_alert] ==
             AlertFilters.filter_by_duration_type(@alerts, :anytime, @now)
  end
end
