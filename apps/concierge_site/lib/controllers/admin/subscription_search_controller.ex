defmodule ConciergeSite.Admin.SubscriptionSearchController do
  use ConciergeSite.Web, :controller
  use Guardian.Phoenix.Controller
  alias ConciergeSite.AdminUserPolicy
  alias AlertProcessor.{Model.User, Repo, Subscription.Diagnostic}

  def create(conn, %{"user_id" => user_id, "search" => search_params}, admin, _claims) do
    with true <- AdminUserPolicy.can?(admin, :show_user_subscriptions),
      {:ok, user} <- get_user(user_id),
      {:ok, diagnoses} <- Diagnostic.diagnose_alert(user, search_params) do
        render conn, :new, user: user, diagnoses: diagnoses
    else
      {:error, :no_user} ->
        conn
        |> put_flash(:error, "That user does not exist")
        |> redirect(to: "/admin_users")
      {:error, user} ->
        conn
        |> put_flash(:error, "There was an error with the search, please try a later date")
        |> render(:new, user: user, diagnoses: [])
      false ->
        render_unauthorized(conn)
    end
  end

  defp get_user(id) do
    case Repo.get_by(User, id: id) do
      %User{} = user -> {:ok, user}
      _ -> {:error, :no_user}
    end
  end

  def new(conn, %{"user_id" => user_id}, _admin, _claims) do
    case Repo.get_by(User, id: user_id) do
      %User{} = user ->
        render conn, :new, user: user, diagnoses: []
      _ ->
        conn
        |> put_flash(:error, "That user does not exist")
        |> redirect(to: "/admin_users")
    end
  end
end
