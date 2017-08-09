defmodule ConciergeSite.ImpersonateSessionPolicyTest do
  use AlertProcessor.DataCase
  import AlertProcessor.Factory
  alias ConciergeSite.ImpersonateSessionPolicy

  describe "impersonate_user" do
    test "allows admins with the application_administration role to impersonate users with the user role" do
      admin = insert(:user, role: "application_administration")
      user = insert(:user, role: "user")

      assert ImpersonateSessionPolicy.can?(admin, :impersonate_user, user)
    end

    test "denies admins with the application_administration role impersonating users with an admin role" do
      admin = insert(:user, role: "application_administration")
      user = insert(:user, role: "customer_support")

      refute ImpersonateSessionPolicy.can?(admin, :impersonate_user, user)
    end

    test "allows admins with the customer_support role to impersonate users with the user role" do
      admin = insert(:user, role: "customer_support")
      user = insert(:user, role: "user")

      assert ImpersonateSessionPolicy.can?(admin, :impersonate_user, user)
    end

    test "denies admins with the customer_support role impersonating users with an admin role" do
      admin = insert(:user, role: "customer_support")
      user = insert(:user, role: "customer_support")

      refute ImpersonateSessionPolicy.can?(admin, :impersonate_user, user)
    end

    test "denies admins with the deactivated_admin role" do
      admin = insert(:user, role: "deactivated_admin")
      user = insert(:user, role: "user")

      refute ImpersonateSessionPolicy.can?(admin, :impersonate_user, user)
    end

    test "denies regular users" do
      user = insert(:user, role: "user")
      user_to_impersonate = insert(:user, role: "user")

      refute ImpersonateSessionPolicy.can?(user, :impersonate_user, user_to_impersonate)
    end
  end
end
