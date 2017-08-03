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
end
