defmodule ConciergeSite.Guardian do
  @moduledoc "Implements Guardian callbacks, Guardian.DB integration, and user permissions."

  use Guardian,
    otp_app: :concierge_site,
    allowed_algos: ["HS512"],
    allowed_drift: 2000,
    issuer: "AlertsConcierge",
    permissions: %{admin: [:all]},
    ttl: {60, :minutes},
    verify_issuer: true,
    verify_module: Guardian.JWT

  use Guardian.Permissions, encoding: Guardian.Permissions.BitwiseEncoding

  alias AlertProcessor.{Model.User, Repo}

  @impl Guardian
  def subject_for_token(%User{} = user, _claims), do: {:ok, "User:#{user.id}"}
  def subject_for_token(_resource, _claims), do: {:error, "Unknown resource type"}

  @impl Guardian
  def resource_from_claims(%{"sub" => "User:" <> id}), do: {:ok, Repo.get(User, id)}
  def resource_from_claims(_claims), do: {:error, "Unknown resource type"}

  @impl Guardian
  def build_claims(claims, resource, _opts) do
    {:ok, encode_permissions_into_claims!(claims, permissions_for(resource))}
  end

  @impl Guardian
  def after_encode_and_sign(resource, claims, token, _options) do
    with {:ok, _} <- Guardian.DB.after_encode_and_sign(resource, claims["typ"], claims, token) do
      {:ok, token}
    end
  end

  @impl Guardian
  def on_verify(claims, token, _options) do
    with {:ok, _} <- Guardian.DB.on_verify(claims, token) do
      {:ok, claims}
    end
  end

  @impl Guardian
  def on_revoke(claims, token, _options) do
    with {:ok, _} <- Guardian.DB.on_revoke(claims, token) do
      {:ok, claims}
    end
  end

  defp permissions_for(%User{role: "admin"}), do: %{admin: max()}
  defp permissions_for(_resource), do: %{}
end
