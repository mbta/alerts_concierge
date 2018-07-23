defmodule ConciergeSite.AdminUserPolicy do
  @moduledoc false
  alias AlertProcessor.Model.User

  @application_admin_only_actions ~w(
    list_admin_users
    create_admin_users
    show_admin_user
    deactivate_admin_user
    activate_admin_user
    send_targeted_message
    update_admin_roles
  )a

  @customer_service_actions ~w(
    show_user_subscriptions
  )a

  def can?(%User{role: "application_administration"}, action)
      when action in @application_admin_only_actions,
      do: true

  def can?(%User{role: "application_administration"}, action)
      when action in @customer_service_actions,
      do: true

  def can?(%User{}, action) when action in @application_admin_only_actions, do: false

  def can?(%User{role: "customer_support"}, action) when action in @customer_service_actions,
    do: true

  def can?(%User{}, action) when action in @customer_service_actions, do: false
end
