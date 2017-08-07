defmodule ConciergeSite.Admin.AdminUserView do
  use ConciergeSite.Web, :view
  alias AlertProcessor.Model.User

  def display_role(%User{role: "application_administration"}), do: "Application Administration"
  def display_role(%User{role: "customer_support"}), do: "Customer Support"
  def display_role(%User{}), do: "User"

  def account_status(%User{role: "deactivated_admin"}), do: "Inactive"
  def account_status(%User{}), do: "Active"
end
