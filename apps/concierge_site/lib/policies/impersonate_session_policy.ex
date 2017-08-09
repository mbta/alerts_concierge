defmodule ConciergeSite.ImpersonateSessionPolicy do
  alias AlertProcessor.Model.User

  @admin_roles ~w(application_administration customer_support)

  def can?(%User{role: admin_role}, :impersonate_user, %User{role: "user"})when admin_role in @admin_roles, do: true
  def can?(%User{}, :impersonate_user, %User{}), do: false
end
