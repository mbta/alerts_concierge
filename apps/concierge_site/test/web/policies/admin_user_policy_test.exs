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

    test "denies users with the deactivated_admin role" do
      user = insert(:user, role: "deactivated_admin")
      refute AdminUserPolicy.can?(user, :list_admin_users)
    end

    test "denies regular users" do
      user = insert(:user, role: "user")
      refute AdminUserPolicy.can?(user, :list_admin_users)
    end
  end

  describe "show_admin_user" do
    test "allows users with the application_administration role" do
      user = insert(:user, role: "application_administration")
      assert AdminUserPolicy.can?(user, :show_admin_user)
    end

    test "denies users with the customer_support role" do
      user = insert(:user, role: "customer_support")
      refute AdminUserPolicy.can?(user, :show_admin_user)
    end

    test "denies users with the deactivated_admin role" do
      user = insert(:user, role: "deactivated_admin")
      refute AdminUserPolicy.can?(user, :show_admin_user)
    end

    test "denies regular users" do
      user = insert(:user, role: "user")
      refute AdminUserPolicy.can?(user, :show_admin_user)
    end
  end

  describe "deactivate_admin_user" do
    test "allows users with the application_administration role" do
      user = insert(:user, role: "application_administration")
      assert AdminUserPolicy.can?(user, :deactivate_admin_user)
    end

    test "denies users with the customer_support role" do
      user = insert(:user, role: "customer_support")
      refute AdminUserPolicy.can?(user, :deactivate_admin_user)
    end

    test "denies users with the deactivated_admin role" do
      user = insert(:user, role: "deactivated_admin")
      refute AdminUserPolicy.can?(user, :deactivate_admin_user)
    end

    test "denies regular users" do
      user = insert(:user, role: "user")
      refute AdminUserPolicy.can?(user, :deactivate_admin_user)
    end
  end
end
