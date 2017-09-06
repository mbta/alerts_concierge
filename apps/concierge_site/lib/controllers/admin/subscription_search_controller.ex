defmodule ConciergeSite.Admin.SubscriptionSearchController do
  use ConciergeSite.Web, :controller
  use Guardian.Phoenix.Controller
  alias ConciergeSite.AdminUserPolicy
  alias AlertProcessor.{Model.User, Repo, Subscription.Snapshot}

  def create(conn, %{"user_id" => user_id, "search" => search_params}, admin, _claims) do
    with true <- AdminUserPolicy.can?(admin, :show_user_subscriptions),
      {:ok, user} <- get_user(user_id),
      {:ok, snapshots} <- get_snapshots(user, search_params) do
        render conn, :new, user: user, snapshots: snapshots
    else
      {:error, :no_user} ->
        conn
        |> put_flash(:error, "That user does not exist")
        |> redirect(to: "/admin_users")
      {:error, user} ->
        conn
        |> put_flash(:error, "There was an error with the search, please try again")
        |> render(:new, user: user, snapshots: [])
      false ->
        handle_unauthorized(conn)
    end
  end

  defp get_user(id) do
    case Repo.get_by(User, id: id) do
      %User{} = user -> {:ok, user}
      _ -> {:error, :no_user}
    end
  end

  defp get_snapshots(user, params) do
    date_params = params["alert_date"]
    date = Enum.reduce(date_params, %{}, fn({k, v}, acc) ->
      Map.put(acc, k, String.to_integer(v))
    end)
    erl_param = {{date["year"], date["month"], date["day"]}, {date["hour"], date["min"], 0}}

    case Calendar.DateTime.from_erl(erl_param, "America/New_York") do
      {:ok, datetime} ->
        {:ok, Snapshot.get_snapshots_by_datetime(user, datetime)}
      _ ->
        {:error, user}
    end
  end

  def new(conn, %{"user_id" => user_id}, _admin, _claims) do
    case Repo.get_by(User, id: user_id) do
      %User{} = user ->
        render conn, :new, user: user, snapshots: []
      _ ->
        conn
        |> put_flash(:error, "That user does not exist")
        |> redirect(to: "/admin_users")
    end
  end

  defp handle_unauthorized(conn) do
    conn
    |> put_status(403)
    |> render(ConciergeSite.ErrorView, "403.html", %{})
  end
end
