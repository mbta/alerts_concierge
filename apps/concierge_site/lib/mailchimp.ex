defmodule ConciergeSite.Mailchimp do
  @moduledoc """
  functions for sending unsubscribes and subscribes
  """

  require Logger
  alias AlertProcessor.Helpers.ConfigHelper
  alias AlertProcessor.Model.User
  alias AlertProcessor.Repo
  alias HTTPoison

  @spec add_member(User.t()) :: :ok | :error
  def add_member(%{id: id, email: email, digest_opt_in: true}) do
    data =
      Poison.encode!(%{
        "email_address" => email,
        "status" => member_status(true)
      })

    endpoint = "#{api_url()}/3.0/lists/#{list_id()}/members"

    client = client()

    case client.post(endpoint, data, headers()) do
      {:ok, %{status_code: 200}} ->
        :ok

      {_, response} ->
        Logger.metadata(user_id: id)
        Logger.error("Mailchimp failed to add member: #{inspect(response)}")
        :error
    end
  end

  def add_member(_), do: :ok

  @spec send_member_status_update(User.t(), Keyword.t()) :: :ok | :error
  def send_member_status_update(
        %{id: id, email: email, digest_opt_in: digest_opt_in},
        opts \\ [client: HTTPoison]
      ) do
    member_id = :crypto.hash(:md5, email) |> Base.encode16()

    data =
      Poison.encode!(%{
        "status" => member_status(digest_opt_in)
      })

    endpoint = "#{api_url()}/3.0/lists/#{list_id()}/members/#{member_id}"

    client = client()

    case client.patch(endpoint, data, headers()) do
      {:ok, %{status_code: 200}} ->
        :ok

      {_, response} ->
        Logger.metadata(user_id: id)
        Logger.error("Mailchimp failed to update status: #{inspect(response)}")
        :error
    end
  end

  @spec unsubscribe_by_email(String.t()) :: 0 | 1
  def unsubscribe_by_email(email) do
    email
    |> User.for_email()
    |> do_unsubscribe_by_email()
  end

  defp do_unsubscribe_by_email(%User{} = user) do
    user
    |> Ecto.Changeset.change(%{digest_opt_in: false})
    |> Repo.update()

    1
  end

  defp do_unsubscribe_by_email(nil), do: 0

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
end
