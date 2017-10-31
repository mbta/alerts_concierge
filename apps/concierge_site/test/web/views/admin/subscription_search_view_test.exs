defmodule ConciergeSite.Admin.SubscriptionSearchViewTest do
  use ExUnit.Case

  alias ConciergeSite.Admin.SubscriptionSearchView
  alias AlertProcessor.Model.Alert
  import ConciergeSite.HTMLTestHelper

  @diagnosis %{
    alert: %Alert{id: "123", service_effect: "Delay", description: "This is some additional info."},
    passed_sent_alert_filter?: true,
    passed_active_period_filter?: true,
    passed_informed_entity_filter?: true,
    passed_severity_filter?: true,
    matches_any_direction?: true,
    matches_any_facility?: true,
    matches_any_route?: true,
    matches_any_route_type?: true,
    matches_any_stop?: true,
    matches_any_trip?: true,
    passes_vacation_period?: true,
    passes_do_not_disturb?: true,
  }

  describe "alert_title" do
    test "renders the alert id, service_effect, and description" do
      result = SubscriptionSearchView.alert_title([@diagnosis])
      assert html_to_binary(result) =~ "Alert ID: 123"
      assert html_to_binary(result) =~ "Delay"
      assert html_to_binary(result) =~ "This is some additional info."
    end
  end

  describe "do_not_disturb_result" do
    test "success" do
      result = SubscriptionSearchView.do_not_disturb_result(@diagnosis)
      assert html_to_binary(result) =~ "Alert was not filtered by do not disturb period"
      assert html_to_binary(result) =~ "diagnostic-result success"
      assert html_to_binary(result) =~ "diagnostic-check-success"
    end

    test "failure" do
      result = SubscriptionSearchView.do_not_disturb_result(Map.put(@diagnosis, :passes_do_not_disturb?, false))
      assert html_to_binary(result) =~ "Alert was filtered by do not disturb period"
      assert html_to_binary(result) =~ "diagnostic-result failure"
      assert html_to_binary(result) =~ "diagnostic-check-failure"
    end
  end

  describe "vacation_result" do
    test "success" do
      result = SubscriptionSearchView.vacation_result(@diagnosis)
      assert html_to_binary(result) =~ "Alert was not filtered by vacation period"
      assert html_to_binary(result) =~ "diagnostic-result success"
      assert html_to_binary(result) =~ "diagnostic-check-success"
    end

    test "failure" do
      result = SubscriptionSearchView.vacation_result(Map.put(@diagnosis, :passes_vacation_period?, false))
      assert html_to_binary(result) =~ "Alert was filtered by vacation period"
      assert html_to_binary(result) =~ "diagnostic-result failure"
      assert html_to_binary(result) =~ "diagnostic-check-failure"
    end
  end

  describe "sent_alert_result" do
    test "success" do
      result = SubscriptionSearchView.sent_alert_result(@diagnosis)
      assert html_to_binary(result) =~ "Alert was not previously sent"
      assert html_to_binary(result) =~ "diagnostic-result success"
      assert html_to_binary(result) =~ "diagnostic-check-success"
    end

    test "failure" do
      result = SubscriptionSearchView.sent_alert_result(Map.put(@diagnosis, :passed_sent_alert_filter?, false))
      assert html_to_binary(result) =~ "Alert was previously sent"
      assert html_to_binary(result) =~ "diagnostic-result failure"
      assert html_to_binary(result) =~ "diagnostic-check-failure"
    end
  end

  describe "severity_result" do
    test "success" do
      result = SubscriptionSearchView.severity_result(@diagnosis)
      assert html_to_binary(result) =~ "Alert severity matches subscription"
      assert html_to_binary(result) =~ "diagnostic-result success"
      assert html_to_binary(result) =~ "diagnostic-check-success"
    end

    test "failure" do
      result = SubscriptionSearchView.severity_result(Map.put(@diagnosis, :passed_severity_filter?, false))
      assert html_to_binary(result) =~ "Alert severity does not match subscription"
      assert html_to_binary(result) =~ "diagnostic-result failure"
      assert html_to_binary(result) =~ "diagnostic-check-failure"
    end
  end

  describe "active_period_result" do
    test "success" do
      result = SubscriptionSearchView.active_period_result(@diagnosis)
      assert html_to_binary(result) =~ "Alert active period matches subscription"
      assert html_to_binary(result) =~ "diagnostic-result success"
      assert html_to_binary(result) =~ "diagnostic-check-success"
    end

    test "failure" do
      result = SubscriptionSearchView.active_period_result(Map.put(@diagnosis, :passed_active_period_filter?, false))
      assert html_to_binary(result) =~ "Alert active period does not match subscription"
      assert html_to_binary(result) =~ "diagnostic-result failure"
      assert html_to_binary(result) =~ "diagnostic-check-failure"
    end
  end

  describe "informed_entity_result" do
    test "success" do
      result = SubscriptionSearchView.informed_entity_result(@diagnosis)
      assert html_to_binary(result) =~ "Alert entities match subscription"
      assert html_to_binary(result) =~ "diagnostic-result success"
      assert html_to_binary(result) =~ "diagnostic-check-success"
    end

    test "direction failure" do
      result = SubscriptionSearchView.informed_entity_result(Map.merge(@diagnosis, %{passed_informed_entity_filter?: false, matches_any_direction?: false}))
      assert html_to_binary(result) =~ "Alert entities do not match subscription:"
      assert html_to_binary(result) =~ "No direction matches"
      assert html_to_binary(result) =~ "At least 1 facility type matches"
      assert html_to_binary(result) =~ "At least 1 route matches"
      assert html_to_binary(result) =~ "At least 1 route type matches"
      assert html_to_binary(result) =~ "At least 1 stop matches"
      assert html_to_binary(result) =~ "At least 1 trip matches"
      assert html_to_binary(result) =~ "diagnostic-result failure"
      assert html_to_binary(result) =~ "diagnostic-check-failure"
    end

    test "facility failure" do
      result = SubscriptionSearchView.informed_entity_result(Map.merge(@diagnosis, %{passed_informed_entity_filter?: false, matches_any_facility?: false}))
      assert html_to_binary(result) =~ "Alert entities do not match subscription:"
      assert html_to_binary(result) =~ "At least 1 direction matches"
      assert html_to_binary(result) =~ "No facility type matches"
      assert html_to_binary(result) =~ "At least 1 route matches"
      assert html_to_binary(result) =~ "At least 1 route type matches"
      assert html_to_binary(result) =~ "At least 1 stop matches"
      assert html_to_binary(result) =~ "At least 1 trip matches"
      assert html_to_binary(result) =~ "diagnostic-result failure"
      assert html_to_binary(result) =~ "diagnostic-check-failure"
    end

    test "route failure" do
      result = SubscriptionSearchView.informed_entity_result(Map.merge(@diagnosis, %{passed_informed_entity_filter?: false, matches_any_route?: false}))
      assert html_to_binary(result) =~ "Alert entities do not match subscription:"
      assert html_to_binary(result) =~ "At least 1 direction matches"
      assert html_to_binary(result) =~ "At least 1 facility type matches"
      assert html_to_binary(result) =~ "No route matches"
      assert html_to_binary(result) =~ "At least 1 route type matches"
      assert html_to_binary(result) =~ "At least 1 stop matches"
      assert html_to_binary(result) =~ "At least 1 trip matches"
      assert html_to_binary(result) =~ "diagnostic-result failure"
      assert html_to_binary(result) =~ "diagnostic-check-failure"
    end

    test "route_type failure" do
      result = SubscriptionSearchView.informed_entity_result(Map.merge(@diagnosis, %{passed_informed_entity_filter?: false, matches_any_route_type?: false}))
      assert html_to_binary(result) =~ "Alert entities do not match subscription:"
      assert html_to_binary(result) =~ "At least 1 direction matches"
      assert html_to_binary(result) =~ "At least 1 facility type matches"
      assert html_to_binary(result) =~ "At least 1 route matches"
      assert html_to_binary(result) =~ "No route type matches"
      assert html_to_binary(result) =~ "At least 1 stop matches"
      assert html_to_binary(result) =~ "At least 1 trip matches"
      assert html_to_binary(result) =~ "diagnostic-result failure"
      assert html_to_binary(result) =~ "diagnostic-check-failure"
    end

    test "stop failure" do
      result = SubscriptionSearchView.informed_entity_result(Map.merge(@diagnosis, %{passed_informed_entity_filter?: false, matches_any_stop?: false}))
      assert html_to_binary(result) =~ "Alert entities do not match subscription:"
      assert html_to_binary(result) =~ "At least 1 direction matches"
      assert html_to_binary(result) =~ "At least 1 facility type matches"
      assert html_to_binary(result) =~ "At least 1 route matches"
      assert html_to_binary(result) =~ "At least 1 route type matches"
      assert html_to_binary(result) =~ "No stop matches"
      assert html_to_binary(result) =~ "At least 1 trip matches"
      assert html_to_binary(result) =~ "diagnostic-result failure"
      assert html_to_binary(result) =~ "diagnostic-check-failure"
    end

    test "trip failure" do
      result = SubscriptionSearchView.informed_entity_result(Map.merge(@diagnosis, %{passed_informed_entity_filter?: false, matches_any_trip?: false}))
      assert html_to_binary(result) =~ "Alert entities do not match subscription:"
      assert html_to_binary(result) =~ "At least 1 direction matches"
      assert html_to_binary(result) =~ "At least 1 facility type matches"
      assert html_to_binary(result) =~ "At least 1 route matches"
      assert html_to_binary(result) =~ "At least 1 route type matches"
      assert html_to_binary(result) =~ "At least 1 stop matches"
      assert html_to_binary(result) =~ "No trip matches"
      assert html_to_binary(result) =~ "diagnostic-result failure"
      assert html_to_binary(result) =~ "diagnostic-check-failure"
    end
  end
end
