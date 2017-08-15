defmodule ConciergeSite.SignInHelper do
  @moduledoc """
  Common functions for user sign in with Guardian
  """

  alias AlertProcessor.Model.User

  def admin_guardian_sign_in(conn, %User{role: "customer_support"} = user) do
    Guardian.Plug.sign_in(conn, user, :token, perms: %{
      default: Guardian.Permissions.max,
      admin: [:customer_support]
    })
  end

  def admin_guardian_sign_in(conn, %User{role: "application_administration"} = user) do
    Guardian.Plug.sign_in(conn, user, :token,
      perms: %{
        default: Guardian.Permissions.max,
        admin: [:customer_support, :application_administration]
    })
  end
end
