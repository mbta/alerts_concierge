defmodule ConciergeSite.Admin.SubscriberViewTest do
  use ExUnit.Case

  import AlertProcessor.Factory
  alias ConciergeSite.Admin.SubscriberView

  describe "account_status" do
    test "returns Active if password is present" do
      user = build(:user)
      assert SubscriberView.account_status(user) == "Active"
    end

    test "returns Disabled if password is empty" do
      user = build(:user, encrypted_password: "")
      assert SubscriberView.account_status(user) == "Disabled"
    end

    test "returns Disabled if password is nil" do
      user = build(:user, encrypted_password: nil)
      assert SubscriberView.account_status(user) == "Disabled"
    end
  end

  describe "blackout_period" do
    test "returns N/A if not present" do
      user = build(:user)
      assert "N/A" = SubscriberView.blackout_period(user)
    end

    test "returns timeframe text" do
      user = build(:user, do_not_disturb_start: ~T[20:00:00], do_not_disturb_end: ~T[06:00:00])
      timeframe_text = SubscriberView.blackout_period(user)
      assert "08:00 PM to 06:00 AM" = IO.iodata_to_binary(timeframe_text)
    end
  end

  describe "vacation_period" do
    test "returns N/A if not present" do
      user = build(:user)
      assert "N/A" = SubscriberView.vacation_period(user)
    end

    test "returns N/A if in past" do
      user = build(:user, vacation_start: DateTime.from_naive!(~N[2016-08-01 12:00:00], "Etc/UTC"), vacation_end: DateTime.from_naive!(~N[2017-08-01 12:00:00], "Etc/UTC"))
      assert "N/A" = SubscriberView.vacation_period(user)
    end

    test "returns timeframe text" do
      user = build(:user, vacation_start: DateTime.from_naive!(~N[2017-08-01 12:00:00], "Etc/UTC"), vacation_end: DateTime.from_naive!(~N[2100-08-01 12:00:00], "Etc/UTC"))
      timeframe_text = SubscriberView.vacation_period(user)
      assert "Tue Aug  1 12:00:00 2017 until Sun Aug  1 12:00:00 2100" = IO.iodata_to_binary(timeframe_text)
    end
  end

  describe "timeframe_string" do
    test "converts subscription start and end times into human friendly iodata" do
      subscription = build(:subscription)
      timeframe_string = SubscriberView.timeframe_string(subscription)
      assert IO.iodata_to_binary(timeframe_string) == "10:00am to  2:00pm"
    end
  end

  describe "subscription_info" do
    test "subscription without origin and destination" do
      subscription = :subscription |> build(alert_priority_type: :low, type: :commuter_rail, origin: nil, destination: nil) |> sunday_subscription()
      subscription_info = SubscriberView.subscription_info(subscription)
      refute html_to_binary(subscription_info) =~ "Origin: "
      refute html_to_binary(subscription_info) =~ "Destination: "
      assert html_to_binary(subscription_info) =~ "10:00am to  2:00pm"
      assert html_to_binary(subscription_info) =~ "Sundays"
      assert html_to_binary(subscription_info) =~ "High-, medium-, and low-priority alerts"
    end

    test "subscription with origin and destination" do
      subscription = :subscription |> build() |> saturday_subscription() |> weekday_subscription()  |> subway_subscription()
      subscription_info = SubscriberView.subscription_info(subscription)
      assert html_to_binary(subscription_info) =~ "Origin: Davis"
      assert html_to_binary(subscription_info) =~ "Destination: Harvard"
      assert html_to_binary(subscription_info) =~ "10:00am to  2:00pm"
      assert html_to_binary(subscription_info) =~ "Weekdays, Saturdays"
      assert html_to_binary(subscription_info) =~ "High- and medium-priority alerts"
    end
  end

  describe "entity_info" do
    test "lets you know if there are no entities" do
      subscription = build(:subscription, informed_entities: [])
      assert "No Entities" = SubscriberView.entity_info(subscription, %{})
    end

    test "amenity" do
      subscription =
        :subscription
        |> build()
        |> Map.put(:informed_entities, amenity_subscription_entities())
        |> amenity_subscription()
      entity_info = SubscriberView.entity_info(subscription, %{})
      assert html_to_binary(entity_info) =~ "Escalator at North Quincy (place-nqncy)"
      assert html_to_binary(entity_info) =~ "Elevator for Green"
    end

    test "bus" do
      subscription =
        :subscription
        |> build()
        |> Map.put(:informed_entities, bus_subscription_entities())
        |> bus_subscription()
      entity_info = SubscriberView.entity_info(subscription, %{})
      assert html_to_binary(entity_info) =~ "Mode: Bus"
      assert html_to_binary(entity_info) =~ "Route: 57A Outbound"
    end

    test "commuter_rail" do
      subscription =
        :subscription
        |> build()
        |> Map.put(:informed_entities, commuter_rail_subscription_entities())
        |> commuter_rail_subscription()
      entity_info = SubscriberView.entity_info(subscription, %{"221" => ~T[19:25:00], "331" => ~T[17:32:00]})
      assert html_to_binary(entity_info) =~ "Mode: Commuter Rail"
      assert html_to_binary(entity_info) =~ "Route: Lowell Line (CR-Lowell) Inbound"
      assert html_to_binary(entity_info) =~ "Stop: Anderson/Woburn (Anderson/ Woburn)"
      assert html_to_binary(entity_info) =~ "Stop: North Station (place-north)"
      assert html_to_binary(entity_info) =~ "Trip: 221 departs at 7:25pm"
      assert html_to_binary(entity_info) =~ "Trip: 331 departs at 5:32pm"
    end

    test "ferry" do
      subscription =
        :subscription
        |> build()
        |> Map.put(:informed_entities, ferry_subscription_entities())
        |> ferry_subscription()
      entity_info = SubscriberView.entity_info(subscription, %{"Boat-F4-Boat-Long-17:00:00-weekday-0" => ~T[17:00:00], "Boat-F4-Boat-Long-17:15:00-weekday-0" => ~T[17:15:00]})
      assert html_to_binary(entity_info) =~ "Mode: Ferry"
      assert html_to_binary(entity_info) =~ "Route: Charlestown Ferry (Boat-F4) Inbound"
      assert html_to_binary(entity_info) =~ "Stop: Charlestown Navy Yard (Boat-Charlestown)"
      assert html_to_binary(entity_info) =~ "Stop: Long Wharf, Boston (Boat-Long)"
      assert html_to_binary(entity_info) =~ "Trip: Boat-F4-Boat-Long-17:00:00-weekday-0 departs at 5:00pm"
      assert html_to_binary(entity_info) =~ "Trip: Boat-F4-Boat-Long-17:15:00-weekday-0 departs at 5:15pm"
    end

    test "subway" do
      subscription =
        :subscription
        |> build()
        |> Map.put(:informed_entities, subway_subscription_entities())
        |> subway_subscription()
      entity_info = SubscriberView.entity_info(subscription, %{})
      assert html_to_binary(entity_info) =~ "Mode: Subway"
      assert html_to_binary(entity_info) =~ "Route: Red Line (Red) Southbound"
      assert html_to_binary(entity_info) =~ "Route: Red Line (Red)"
      assert html_to_binary(entity_info) =~ "Stop: Davis (place-davis)"
      assert html_to_binary(entity_info) =~ "Stop: Harvard (place-harsq)"
    end
  end

  defp html_to_binary(html_list) do
    html_list |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()
  end
end
