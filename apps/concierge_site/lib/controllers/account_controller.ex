defmodule ConciergeSite.AccountController do
  use ConciergeSite.Web, :controller

  alias AlertProcessor.{Model.User, Repo}

  plug :scrub_params, "user" when action in [:create]

  def index(conn, _params) do
    render conn, "index.html"
  end

  def new(conn, _params) do
    account_changeset = User.create_account_changeset(%User{}, %{"sms_toggle" => false})
    render conn, "new.html", account_changeset: account_changeset, errors: []
  end

  def create(conn, %{"user" => user_params}) do
    account_changeset = User.create_account_changeset(%User{}, user_params)
    case Repo.insert(account_changeset) do
      {:ok, user} ->
        conn
        |> Guardian.Plug.sign_in(user)
        |> redirect(to: "/my-subscriptions")
      {:error, changeset} ->
        render conn, "new.html", account_changeset: %{changeset | action: :insert}, errors: errors(changeset)
    end
  end

  defp errors(changeset) do
    Enum.map(changeset.errors, fn({field, _}) ->
      field
    end)
  end
end
