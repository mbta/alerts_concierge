defmodule ConciergeSite.AdminUserPolicyTest do
  use AlertProcessor.DataCase
  import AlertProcessor.Factory
  alias ConciergeSite.AdminUserPolicy

  describe "list_admin_users" do
    test "allows users with the application_administration role" do
      user = insert(:user, role: "application_administration")
      assert AdminUserPolicy.can?(user, :list_admin_users)
    end

    test "denies users with the customer_support role" do
      user = insert(:user, role: "customer_support")
      refute AdminUserPolicy.can?(user, :list_admin_users)
    end

    test "denies regular users" do
      user = insert(:user, role: "user")
      refute AdminUserPolicy.can?(user, :list_admin_users)
    end
  end
end
