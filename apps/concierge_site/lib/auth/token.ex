defmodule ConciergeSite.Auth.Token do
  @moduledoc """
  module to generate jwt tokens to use for auto-login links. password reset, etc.
  """
  alias AlertProcessor.Model.User

  @type time_unit :: :millis | :seconds | :minutes | :hours | :days | :years
  @type token :: String.t()
  @type permissions :: keyword(atom)
  @type ttl :: {integer, time_unit}

  @doc """
  takes a user and opts to return a jwt token generated via guardian.
  """
  @spec issue(User.t(), permissions | nil, ttl | nil) :: {:ok, token, permissions} | {:error, any}
  def issue(%User{} = user) do
    Guardian.encode_and_sign(user, :access, %{perms: %{default: Guardian.Permissions.max()}})
  end

  def issue(%User{} = user, permissions) when is_list(permissions) do
    Guardian.encode_and_sign(user, :access, %{perms: %{default: permissions}})
  end

  def issue(%User{} = user, permissions \\ Guardian.Permissions.max(), ttl) do
    Guardian.encode_and_sign(user, :access, %{perms: %{default: permissions}, ttl: ttl})
  end
end
