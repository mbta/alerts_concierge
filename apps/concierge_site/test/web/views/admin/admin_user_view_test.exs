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

  describe "display_role/1" do
    test "returns admin's role in UI friendly format" do
      admin_role = AdminUserView.display_role(%User{role: "customer_support"})

      assert admin_role == "Customer Support"
    end
  end

  describe "activation_button_text/1" do
    test "returns Deactivate User text in button when admin is active" do
      text = AdminUserView.activation_button_text(%User{role: "customer_support"})

      assert text == "Deactivate User"
    end

    test "returns Reactivate User text in button when admin is deactivated" do
      text = AdminUserView.activation_button_text(%User{role: "deactivated_admin"})

      assert text == "Reactivate User"
    end
  end

  describe "activation_button_icon/1" do
    test "returns icon that corresponds to activate button text" do
      icon = AdminUserView.activation_button_icon(%User{role: "deactivated_admin"})

      assert icon == "fa-user"
    end

    test "returns icon that corresponds to deactivate button text" do
      icon = AdminUserView.activation_button_icon(%User{role: "customer_support"})

      assert icon == "fa-times"
    end
  end

  describe "activation_button_class/1" do
    test "returns button class that corresponds to activate button text" do
      button_class = AdminUserView.activation_button_class(%User{role: "deactivated_admin"})

      assert button_class == "btn btn-primary admin-user-btn"
    end

    test "returns button class that corresponds to deactivate button text" do
      button_class = AdminUserView.activation_button_class(%User{role: "customer_support"})

      assert button_class == "btn btn-outline-primary admin-user-btn"
    end
  end

  describe "activation_path/1" do
    test "returns confirm_activate path for deactivation" do
      path = AdminUserView.activation_path(%User{role: "deactivated_admin"})

      assert path == :confirm_activate
    end

    test "returns confirm_deactivate path for deactivation" do
      path = AdminUserView.activation_path(%User{role: "customer_support"})

      assert path == :confirm_deactivate
    end
  end

  describe "display_admin_log_action/1" do
    test "admin:view-subscriber" do
      action = AdminUserView.display_admin_log_action(%{origin: "admin:view-subscriber"})

      assert action == "View Subscriber"
    end

    test "admin:message-subscriber" do
      action = AdminUserView.display_admin_log_action(%{origin: "admin:message-subscriber"})

      assert action == "Message Subscriber"
    end

    test "admin:impersonate-subscriber" do
      action = AdminUserView.display_admin_log_action(%{origin: "admin:impersonate-subscriber"})

      assert action == "Logged In As Subscriber"
    end

    test "admin:create-admin-account" do
      action = AdminUserView.display_admin_log_action(%{origin: "admin:create-admin-account"})

      assert action == "Create Admin Account"
    end

    test "admin:deactivate-subscriber-account" do
      action = AdminUserView.display_admin_log_action(%{origin: "admin:deactivate-subscriber-account"})

      assert action == "Deactivate Subscriber Account"
    end

    test "admin:deactivate-admin" do
      action = AdminUserView.display_admin_log_action(%{origin: "admin:deactivate-admin"})

      assert action == "Deactivate Admin Account"
    end

    test "admin:change-admin-role" do
      action = AdminUserView.display_admin_log_action(%{origin: "admin:change-admin-role"})

      assert action == "Change Admin Role"
    end

    test "admin:create-subscription" do
      action = AdminUserView.display_admin_log_action(%{origin: "admin:create-subscription"})

      assert action == "Create Subscription"
    end

    test "admin:update-subscription" do
      action = AdminUserView.display_admin_log_action(%{origin: "admin:update-subscription"})

      assert action == "Update Subscription"
    end

    test "admin:delete-subscription" do
      action = AdminUserView.display_admin_log_action(%{origin: "admin:delete-subscription"})

      assert action == "Delete Subscription"
    end

    test "admin:update-subscriber-password" do
      action = AdminUserView.display_admin_log_action(%{origin: "admin:update-subscriber-password"})

      assert action == "Update Subscriber Password"
    end

    test "admin:update-subscriber-account" do
      action = AdminUserView.display_admin_log_action(%{origin: "admin:update-subscriber-account"})

      assert action == "Update Subscriber Account"
    end

    test "admin:create-full-mode-subscription" do
      action = AdminUserView.display_admin_log_action(%{origin: "admin:create-full-mode-subscription"})

      assert action == "Create Full Mode Subscription"
    end

    test "admin:delete-full-mode-subscription" do
      action = AdminUserView.display_admin_log_action(%{origin: "admin:delete-full-mode-subscription"})

      assert action == "Delete Full Mode Subscription"
    end

    test "admin:update-subscriber-vacation" do
      action = AdminUserView.display_admin_log_action(%{origin: "admin:update-subscriber-vacation"})

      assert action == "Update Subscriber Vacation"
    end

    test "admin:remove-subscriber-vacation" do
      action = AdminUserView.display_admin_log_action(%{origin: "admin:remove-subscriber-vacation"})

      assert action == "Remove Subscriber Vacation"
    end

    test "unknown or nil" do
      action1 = AdminUserView.display_admin_log_action(%{origin: nil})
      action2 = AdminUserView.display_admin_log_action(%{origin: "garbage action"})
      assert action1 == "Unknown Action"
      assert action2 == "Unknown Action"
    end
  end

  describe "display_admin_log_time/1" do
    test "returns admin log time in the right format" do
      inserted_at = ~N[2017-08-16 20:26:34.656352]
      time = AdminUserView.display_admin_log_time(%{inserted_at: inserted_at})

      assert time == "08/16/17  8:26 PM"
    end
  end

  describe "admin_log_target/1" do
    test "returns the account email in admin log" do
      email = AdminUserView.admin_log_target(%{item_id: "9999", meta: %{"subscriber_email" => "test@example.com"}})

      assert email == "test@example.com"
    end

    test "returns owner if set" do
      owner = AdminUserView.admin_log_target(%{item_id: "9999", meta: %{"owner" => "1234"}})

      assert owner == "1234"
    end

    test "returns item id if neither are set" do
      item_id = AdminUserView.admin_log_target(%{item_id: "9999", meta: nil})

      assert item_id == "9999"
    end
  end

  describe "admin_log_target_url" do
    test "returns the link to subscriber page if subscriber id is set" do
      link = AdminUserView.admin_log_target_url(%{item_id: "9999", meta: %{"subscriber_id" => "1234"}})

      assert link == "/admin/subscribers/1234"
    end

    test "returns owner if set" do
      link = AdminUserView.admin_log_target_url(%{item_id: "9999", meta: %{"owner" => "1234"}})

      assert link == "/admin/subscribers/1234"
    end

    test "returns item id if neither are set" do
      link = AdminUserView.admin_log_target_url(%{item_id: "9999", meta: nil})

      assert link == "/admin/admin_users/9999"
    end
  end
end
