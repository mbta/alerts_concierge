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
      assert "08-01-2017 until 08-01-2100" = IO.iodata_to_binary(timeframe_text)
    end
  end
end
