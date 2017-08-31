defmodule ConciergeSite.Admin.SubscriptionSearchView do
  use ConciergeSite.Web, :view

  def alert_title([snap | _]) do
    content_tag(:div, class: "admin-table-row diagnostic-title") do
      [
        content_tag(:p, "Alert ID: #{snap.alert.id}", class: "diagnostic-alert id"),
        content_tag(:p, snap.alert.service_effect, class: "diagnostic-alert title"),
        content_tag(:p, snap.alert.description, class: "diagnostic-alert description")
      ]
    end
  end

  def do_not_disturb_result(snapshot) do
    if snapshot.passes_do_not_disturb? do
      content_tag(:div, class: "diagnostic-result success") do
        [
          content_tag(:i, "", class: "fa fa-check-circle"),
          " Alert was not filtered by do_not_disturb"
        ]
      end
    else
      content_tag(:div, class: "diagnostic-result failure") do
        [
          content_tag(:i, "", class: "fa fa-exclamation-circle"),
          " Alert was filtered by do_not_disturb"
        ]
      end
    end
  end

  def vacation_result(snapshot) do
    if snapshot.passes_vacation_period? do
      content_tag(:div, class: "diagnostic-result success") do
        [
          content_tag(:i, "", class: "fa fa-check-circle"),
          " Alert was not filtered by vacation period"
        ]
      end
    else
      content_tag(:div, class: "diagnostic-result failure") do
        [
          content_tag(:i, "", class: "fa fa-exclamation-circle"),
          " Alert was filtered by vacation_period"
        ]
      end
    end
  end

  def sent_alert_result(snapshot) do
    if snapshot.passed_sent_alert_filter? do
      content_tag(:div, class: "diagnostic-result success") do
        [
          content_tag(:i, "", class: "fa fa-check-circle"),
          " Alert was not previously sent"
        ]
      end
    else
      content_tag(:div, class: "diagnostic-result failure") do
        [
          content_tag(:i, "", class: "fa fa-exclamation-circle"),
          " Alert was previously sent"
        ]
      end
    end
  end

  def severity_result(snapshot) do
    if snapshot.passed_severity_filter? do
      content_tag(:div, class: "diagnostic-result success") do
        [
          content_tag(:i, "", class: "fa fa-check-circle"),
          " Alert severity matches subscription"
        ]
      end
    else
      content_tag(:div, class: "diagnostic-result failure") do
        [
          content_tag(:i, "", class: "fa fa-exclamation-circle"),
          " Alert severity does not match subscription"
        ]
      end
    end
  end

  def active_period_result(snapshot) do
    if snapshot.passed_active_period_filter? do
      content_tag(:div, class: "diagnostic-result success") do
        [
          content_tag(:i, "", class: "fa fa-check-circle"),
          " Alert active period matches subscription"
        ]
      end
    else
      content_tag(:div, class: "diagnostic-result failure") do
        [
          content_tag(:i, "", class: "fa fa-exclamation-circle"),
          " Alert active period does not match subscription"
        ]
      end
    end
  end

  def informed_entity_result(snapshot) do
    if snapshot.passed_informed_entity_filter? do
      content_tag(:div, class: "diagnostic-result success") do
        [
          content_tag(:i, "", class: "fa fa-check-circle"),
          " Alert entities match subcription"
        ]
      end
    else
      content_tag(:div, class: "diagnostic-result failure") do
        [
          content_tag(:i, "", class: "fa fa-exclamation-circle"),
          " Alert entities do not match subscription:",
          direction_result(snapshot),
          facility_result(snapshot),
          route_result(snapshot),
          route_type_result(snapshot),
          stop_result(snapshot),
          trip_result(snapshot)
        ]
      end
    end
  end

  defp direction_result(snapshot) do
    if snapshot.matches_any_direction? do
      content_tag(:div, class: "diagnostic-result-entity") do
        [
          content_tag(:i, "", class: "fa fa-check-circle"),
          " At least 1 direction matches"
        ]
      end
    else
      content_tag(:div, class: "diagnostic-result-entity") do
        [
          content_tag(:i, "", class: "fa fa-exclamation-circle"),
          " No direction matches"
        ]
      end
    end
  end

  defp facility_result(snapshot) do
    if snapshot.matches_any_facility? do
      content_tag(:div, class: "diagnostic-result-entity") do
        [
          content_tag(:i, "", class: "fa fa-check-circle"),
          " At least 1 facility type matches"
        ]
      end
    else
      content_tag(:div, class: "diagnostic-result-entity") do
        [
          content_tag(:i, "", class: "fa fa-exclamation-circle"),
          " No facility type matches"
        ]
      end
    end
  end

  defp route_result(snapshot) do
    if snapshot.matches_any_route? do
      content_tag(:div, class: "diagnostic-result-entity") do
        [
          content_tag(:i, "", class: "fa fa-check-circle"),
          " At least 1 route matches"
        ]
      end
    else
      content_tag(:div, class: "diagnostic-result-entity") do
        [
          content_tag(:i, "", class: "fa fa-exclamation-circle"),
          " No route matches"
        ]
      end
    end
  end

  defp route_type_result(snapshot) do
    if snapshot.matches_any_direction? do
      content_tag(:div, class: "diagnostic-result-entity") do
        [
          content_tag(:i, "", class: "fa fa-check-circle"),
          " At least 1 route_type matches"
        ]
      end
    else
      content_tag(:div, class: "diagnostic-result-entity") do
        [
          content_tag(:i, "", class: "fa fa-exclamation-circle"),
          " No route_type matches"
        ]
      end
    end
  end

  defp stop_result(snapshot) do
    if snapshot.matches_any_stop? do
      content_tag(:div, class: "diagnostic-result-entity") do
        [
          content_tag(:i, "", class: "fa fa-check-circle"),
          " At least 1 stop matches"
        ]
      end
    else
      content_tag(:div, class: "diagnostic-result-entity") do
        [
          content_tag(:i, "", class: "fa fa-exclamation-circle"),
          " No stop matches"
        ]
      end
    end
  end

  defp trip_result(snapshot) do
    if snapshot.matches_any_direction? do
      content_tag(:div, class: "diagnostic-result-entity") do
        [
          content_tag(:i, "", class: "fa fa-check-circle"),
          " At least 1 trip matches"
        ]
      end
    else
      content_tag(:div, class: "diagnostic-result-entity") do
        [
          content_tag(:i, "", class: "fa fa-exclamation-circle"),
          " No trip matches"
        ]
      end
    end
  end
end
