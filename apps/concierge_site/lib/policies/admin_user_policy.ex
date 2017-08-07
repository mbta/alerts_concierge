defmodule ConciergeSite.AdminUserPolicy do
  alias AlertProcessor.Model.User

  def can?(%User{role: "application_administration"}, :list_admin_users), do: true
  def can?(%User{}, :list_admin_users), do: false

  def can?(%User{role: "application_administration"}, :create_admin_users), do: true
  def can?(%User{}, :create_admin_users), do: false

  def can?(%User{role: "application_administration"}, :show_admin_user), do: true
  def can?(%User{}, :show_admin_user), do: false

  def can?(%User{role: "application_administration"}, :deactivate_admin_user), do: true
  def can?(%User{}, :deactivate_admin_user), do: false
end
