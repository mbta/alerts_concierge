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

  defp success(body, class \\ nil) do
    content_tag(:div, class: "diagnostic-result#{class} success") do
      [
        content_tag(:i, "", class: "fa fa-check-circle diagnostic-check-success"),
        " ",
        body
      ]
    end
  end

  defp failure(body) do
    content_tag(:div, class: "diagnostic-result failure") do
      [
        content_tag(:i, "", class: "fa fa-exclamation-circle diagnostic-check-failure"),
        " ",
        body
      ]
    end
  end

  def do_not_disturb_result(snapshot) do
    if snapshot.passes_do_not_disturb? do
      success("Alert was not filtered by do_not_disturb")
    else
      failure("Alert was filtered by do_not_disturb")
    end
  end

  def vacation_result(snapshot) do
    if snapshot.passes_vacation_period? do
      success("Alert was not filtered by vacation period")
    else
      failure("Alert was filtered by vacation_period")
    end
  end

  def sent_alert_result(snapshot) do
    if snapshot.passed_sent_alert_filter? do
      success("Alert was not previously sent")
    else
      failure("Alert was previously sent")
    end
  end

  def severity_result(snapshot) do
    if snapshot.passed_severity_filter? do
      success("Alert severity matches subscription")
    else
      failure("Alert severity does not match subscription")
    end
  end

  def active_period_result(snapshot) do
    if snapshot.passed_active_period_filter? do
      success("Alert active period matches subscription")
    else
      failure("Alert active period does not match subscription")
    end
  end

  def informed_entity_result(snapshot) do
    if snapshot.passed_informed_entity_filter? do
      success("Alert entities match subcription")
    else
      failure([
        "Alert entities do not match subscription:",
        direction_result(snapshot),
        facility_result(snapshot),
        route_result(snapshot),
        route_type_result(snapshot),
        stop_result(snapshot),
        trip_result(snapshot)
      ])
    end
  end

  defp direction_result(snapshot) do
    if snapshot.matches_any_direction? do
      success("At least 1 direction matches", "-entity")
    else
      failure("No direction matches")
    end
  end

  defp facility_result(snapshot) do
    if snapshot.matches_any_facility? do
      success("At least 1 facility type matches", "-entity")
    else
      failure("No facility type matches")
    end
  end

  defp route_result(snapshot) do
    if snapshot.matches_any_route? do
      success("At least 1 route matches", "-entity")
    else
      failure("No route matches")
    end
  end

  defp route_type_result(snapshot) do
    if snapshot.matches_any_direction? do
      success("At least 1 route_type matches", "-entity")
    else
      failure("No route_type matches")
    end
  end

  defp stop_result(snapshot) do
    if snapshot.matches_any_stop? do
      success("At least 1 stop matches", "-entity")
    else
      failure("No stop matches")
    end
  end

  defp trip_result(snapshot) do
    if snapshot.matches_any_direction? do
      success("At least 1 trip matches", "-entity")
    else
      failure("No trip matches")
    end
  end
end
