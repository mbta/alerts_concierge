defmodule ConciergeSite.Mailchimp do
  @moduledoc """
  Handles updating digest subscribership in Mailchimp and receiving updates from the service.
  """

  require Logger
  alias AlertProcessor.Helpers.ConfigHelper
  alias AlertProcessor.Model.User
  alias AlertProcessor.Repo
  alias Ecto.Changeset

  @doc "Update a user's subscriber status in Mailchimp to reflect their `digest_opt_in` value."
  @spec update_member(User.t()) :: :ok | :error
  def update_member(%{id: id, email: email, digest_opt_in: digest_opt_in}) do
    member_id = :crypto.hash(:md5, email) |> Base.encode16()

    data =
      Poison.encode!(%{
        "email_address" => email,
        "status" => member_status(digest_opt_in),
        "status_if_new" => member_status(digest_opt_in)
      })

    endpoint = "#{api_url()}/3.0/lists/#{list_id()}/members/#{member_id}"

    case client().put(endpoint, data, headers()) do
      {:ok, %{status_code: 200}} ->
        :ok

      {_, response} ->
        Logger.error("Mailchimp event=update_failed user_id=#{id} #{inspect(response)}")
        :error
    end
  end

  @doc "Handle a notification from Mailchimp that a user unsubscribed from the list."
  @spec handle_unsubscribed(String.t(), String.t()) :: {0 | 1, String.t()}
  def handle_unsubscribed(secret, email) do
    if secret == webhook_secret() do
      email |> User.for_email() |> do_handle_unsubscribed()
    else
      {0, "skipped"}
    end
  end

  defp do_handle_unsubscribed(%User{} = user) do
    user |> Changeset.change(%{digest_opt_in: false}) |> Repo.update()
    {1, "updated"}
  end

  defp do_handle_unsubscribed(_), do: {0, "updated"}

  @doc "Handle a notification from Mailchimp that a user changed their email for the list."
  @spec handle_email_changed(String.t(), String.t(), String.t()) :: {0 | 1, String.t()}
  def handle_email_changed(secret, old_email, new_email) do
    if secret == webhook_secret() do
      do_handle_email_changed({User.for_email(old_email), User.for_email(new_email)}, new_email)
    else
      {0, "skipped"}
    end
  end

  defp do_handle_email_changed({%User{} = user, nil}, new_email) do
    user |> Changeset.change(%{email: new_email}) |> Repo.update()
    {1, "updated"}
  end

  defp do_handle_email_changed(_, _), do: {0, "updated"}

  @spec member_status(boolean) :: String.t()
  defp member_status(true), do: "subscribed"
  defp member_status(false), do: "unsubscribed"

  @spec headers() :: Keyword.t()
  defp headers() do
    [Authorization: "apikey #{api_key()}", "Content-Type": "application/json"]
  end

  @spec api_url() :: String.t()
  defp api_url(), do: ConfigHelper.get_string(:mailchimp_api_url, :concierge_site)

  @spec api_key() :: String.t()
  defp api_key(), do: ConfigHelper.get_string(:mailchimp_api_key, :concierge_site)

  @spec list_id() :: String.t()
  defp list_id(), do: ConfigHelper.get_string(:mailchimp_list_id, :concierge_site)

  @spec client() :: module()
  defp client(), do: Application.get_env(:concierge_site, :mailchimp_api_client)

  @spec webhook_secret() :: String.t()
  defp webhook_secret(), do: :crypto.hash(:md5, api_key()) |> Base.encode16()
end
