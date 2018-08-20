defmodule AlertProcessor.AlertFiltersTest do
  use ExUnit.Case, async: true
  alias AlertProcessor.Model.Alert
  alias AlertProcessor.AlertFilters

  @now DateTime.from_naive!(~N[2018-01-01 10:00:00.000], "Etc/UTC")

  @recent_alert %Alert{
    last_push_notification: DateTime.from_naive!(~N[2018-01-01 09:30:00.000], "Etc/UTC"),
    header: "recent"
  }

  @old_alert %Alert{
    last_push_notification: DateTime.from_naive!(~N[2000-01-01 00:00:00.000], "Etc/UTC"),
    header: "old"
  }

  @alerts [@old_alert, @recent_alert]

  test "match recent alerts" do
    assert [@recent_alert] == AlertFilters.filter_by_duration_type(@alerts, :recent, @now)
  end

  test "match older alerts" do
    assert [@old_alert] == AlertFilters.filter_by_duration_type(@alerts, :older, @now)
  end

  test "match all alerts" do
    assert [@old_alert, @recent_alert] ==
             AlertFilters.filter_by_duration_type(@alerts, :anytime, @now)
  end
end
