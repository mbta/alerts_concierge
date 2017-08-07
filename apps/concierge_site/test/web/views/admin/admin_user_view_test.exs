defmodule ConciergeSite.Admin.AdminUserViewTest do
  use ExUnit.Case
  alias ConciergeSite.Admin.AdminUserView
  alias AlertProcessor.Model.User

  describe "account_status/1" do
    test "returns Active when the admin is not deactivated" do
      account_status = AdminUserView.account_status(%User{role: "customer_support"})

      assert account_status == "Active"
    end

    test "returns Inactive when the admin is deactivated" do
      account_status = AdminUserView.account_status(%User{role: "deactivated_admin"})

      assert account_status == "Inactive"
    end
  end
end
