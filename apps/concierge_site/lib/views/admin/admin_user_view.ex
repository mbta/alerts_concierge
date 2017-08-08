defmodule ConciergeSite.Admin.AdminUserView do
  use ConciergeSite.Web, :view
  alias AlertProcessor.Model.User

  def display_role(%User{role: "application_administration"}), do: "Application Administration"
  def display_role(%User{role: "customer_support"}), do: "Customer Support"
  def display_role(%User{role: "deactivated_admin"}), do: "Deactivated Admin"
  def display_role(%User{}), do: "User"

  def account_status(%User{role: "deactivated_admin"}), do: "Inactive"
  def account_status(%User{}), do: "Active"

  def activation_button_text(%User{role: "deactivated_admin"}), do: "Reactivate User"
  def activation_button_text(%User{}), do: "Deactivate User"

  def activation_button_icon(%User{role: "deactivated_admin"}), do: "fa-user"
  def activation_button_icon(%User{}), do: "fa-times"

  def activation_button_class(%User{role: "deactivated_admin"}), do: "btn btn-primary admin-user-btn"
  def activation_button_class(%User{}), do: "btn btn-outline-primary admin-user-btn"

  def activation_path(%User{role: "deactivated_admin"}), do: :confirm_activate
  def activation_path(%User{}), do: :confirm_deactivate
end
