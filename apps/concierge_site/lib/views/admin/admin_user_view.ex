defmodule ConciergeSite.Admin.AdminUserView do
  use ConciergeSite.Web, :view
  alias AlertProcessor.Model.User
  alias Calendar.DateTime
  alias Calendar.Strftime

  def display_role(%User{role: "application_administration"}), do: "Application Administration"
  def display_role(%User{role: "customer_support"}), do: "Customer Support"
  def display_role(%User{role: "deactivated_admin"}), do: "Deactivated Admin"
  def display_role(%User{}), do: "User"

  def account_status(%User{role: "deactivated_admin"}), do: "Inactive"
  def account_status(%User{}), do: "Active"

  def activation_button_text(%User{role: "deactivated_admin"}), do: "Reactivate User"
  def activation_button_text(%User{role: "user"}), do: ""
  def activation_button_text(%User{}), do: "Deactivate User"

  def activation_button_icon(%User{role: "deactivated_admin"}), do: "fa-user"
  def activation_button_icon(%User{}), do: "fa-times"

  def activation_button_class(%User{role: "deactivated_admin"}), do: "btn btn-primary admin-user-btn"
  def activation_button_class(%User{}), do: "btn btn-outline-primary admin-user-btn"

  def activation_path(%User{role: "deactivated_admin"}), do: :confirm_activate
  def activation_path(%User{}), do: :confirm_deactivate

  def display_admin_log_action(%{origin: "admin:view-subscriber"}), do: "View Subscriber"
  def display_admin_log_action(%{origin: "admin:message-subscriber"}), do: "Message Subscriber"
  def display_admin_log_action(%{origin: "admin:impersonate-subscriber"}), do: "Logged In As Subscriber"
  def display_admin_log_action(%{origin: "admin:create-admin-account"}), do: "Create Admin Account"
  def display_admin_log_action(%{origin: "admin:deactivate-subscriber-account"}), do: "Deactivate Subscriber Account"
  def display_admin_log_action(%{origin: "admin:deactivate-admin"}), do: "Deactivate Admin Account"
  def display_admin_log_action(%{origin: "admin:change-admin-role"}), do: "Change Admin Role"
  def display_admin_log_action(%{origin: "admin:create-subscription"}), do: "Create Subscription"
  def display_admin_log_action(%{origin: "admin:update-subscription"}), do: "Update Subscription"
  def display_admin_log_action(%{origin: "admin:delete-subscription"}), do: "Delete Subscription"
  def display_admin_log_action(%{origin: "admin:update-subscriber-password"}), do: "Update Subscriber Password"
  def display_admin_log_action(%{origin: "admin:update-subscriber-account"}), do: "Update Subscriber Account"
  def display_admin_log_action(%{origin: "admin:create-full-mode-subscription"}), do: "Create Full Mode Subscription"
  def display_admin_log_action(%{origin: "admin:delete-full-mode-subscription"}), do: "Delete Full Mode Subscription"
  def display_admin_log_action(%{origin: "admin:update-subscriber-vacation"}), do: "Update Subscriber Vacation"
  def display_admin_log_action(%{origin: "admin:remove-subscriber-vacation"}), do: "Remove Subscriber Vacation"
  def display_admin_log_action(_), do: "Unknown Action"

  def display_admin_log_time(%{inserted_at: inserted_at}) do
    {:ok, datetime} = DateTime.from_naive(inserted_at, "Etc/UTC")
    Strftime.strftime!(datetime, "%m/%d/%y %l:%M %p")
  end

  def admin_log_target(%{meta: %{"subscriber_email" => email}}), do: email
  def admin_log_target(%{meta: %{"owner" => owner_id}}), do: owner_id
  def admin_log_target(%{item_id: item_id}), do: item_id

  def admin_log_target_url(%{meta: %{"subscriber_id" => subscriber_id}}) do
    ConciergeSite.Router.Helpers.admin_subscriber_path(ConciergeSite.Endpoint, :show, subscriber_id)
  end
  def admin_log_target_url(%{meta: %{"owner" => owner_id}}) do
    ConciergeSite.Router.Helpers.admin_subscriber_path(ConciergeSite.Endpoint, :show, owner_id)
  end
  def admin_log_target_url(%{item_id: item_id}) do
    ConciergeSite.Router.Helpers.admin_admin_user_path(ConciergeSite.Endpoint, :show, item_id)
  end
end
