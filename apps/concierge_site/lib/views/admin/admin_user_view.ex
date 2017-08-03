defmodule ConciergeSite.Admin.AdminUserView do
  use ConciergeSite.Web, :view
  alias AlertProcessor.Model.User

  def display_role(%User{role: "application_administration"}), do: "Application Administration"
  def display_role(%User{role: "customer_support"}), do: "Customer Support"
  def display_role(%User{}), do: "User"
end
