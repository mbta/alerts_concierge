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
    test "returns correponding admin log action from paper trail" do
      action = AdminUserView.display_admin_log_action(%{origin: "admin:view-subscriber"})

      assert action == "View Subscriber"
    end
  end

  describe "display_admin_log_time/1" do
    test "returns admin log time in the right format" do
      inserted_at = ~N[2017-08-16 20:26:34.656352]
      time = AdminUserView.display_admin_log_time(%{inserted_at: inserted_at})

      assert time == "08/16/17  8:26 PM"
    end
  end

  describe "admin_log_subscriber_email/1" do
    test "returns the account email in admin log" do
      email = AdminUserView.admin_log_subscriber_email(%{meta: %{"subscriber_email" => "test@example.com"}})

      assert email == "test@example.com"
    end
  end
end
