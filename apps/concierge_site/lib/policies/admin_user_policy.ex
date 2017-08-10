defmodule ConciergeSite.AdminUserPolicy do
  alias AlertProcessor.Model.User

  @application_admin_only_actions ~w(
    list_admin_users
    create_admin_users
    show_admin_user
    deactivate_admin_user
    activate_admin_user
    send_targeted_message
  )a

  def can?(%User{role: "application_administration"}, action) when action in @application_admin_only_actions, do: true
  def can?(%User{}, action) when action in @application_admin_only_actions, do: false
end
