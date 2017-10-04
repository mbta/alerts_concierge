defmodule ConciergeSite.Admin.SubscriptionSearchController do
  use ConciergeSite.Web, :controller
  use Guardian.Phoenix.Controller
  alias ConciergeSite.AdminUserPolicy
  alias AlertProcessor.{Model.User, Repo, Subscription}
  alias Subscription.{Diagnostic, DisplayInfo}

  def create(conn, %{"user_id" => user_id, "search" => search_params}, admin, _claims) do
    with true <- AdminUserPolicy.can?(admin, :show_user_subscriptions),
      {:ok, user} <- get_user(user_id),
      {:ok, diagnoses} <- Diagnostic.diagnose_alert(user, search_params),
      sorted_diagnoses <- Diagnostic.sort(diagnoses),
      {:ok, departure_time_map} <-
        sorted_diagnoses.all
        |> Enum.map(&(&1.subscription))
        |> DisplayInfo.departure_times_for_subscriptions() do
        render conn, :new, user: user, diagnoses: sorted_diagnoses, departure_time_map: departure_time_map
    else
      {:error, :no_user} ->
        conn
        |> put_flash(:error, "That user does not exist")
        |> redirect(to: "/admin_users")
      {:error, user} ->
        conn
        |> put_flash(:error, "That alert ID and date does not return any subscriptions. The user did not have any valid subscriptions on that date, or that alert did not exist.")
        |> render(:new, user: user, diagnoses: %{all: [], succeeded: [], failed: []}, departure_time_map: %{})
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
        render(conn, :new, user: user, diagnoses: %{all: [], succeeded: [], failed: []}, departure_time_map: %{})
      _ ->
        conn
        |> put_flash(:error, "That user does not exist")
        |> redirect(to: "/admin_users")
    end
  end
end
