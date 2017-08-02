defmodule ConciergeSite.AdminUserPolicy do
  alias AlertProcessor.Model.User

  def can?(%User{role: "application_administration"}, :list_admin_users), do: true
  def can?(_user, :list_admin_users), do: false
end
