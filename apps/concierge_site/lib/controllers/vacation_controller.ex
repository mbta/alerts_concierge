defmodule ConciergeSite.VacationController do
  use ConciergeSite.Web, :controller
  use Guardian.Phoenix.Controller
  alias AlertProcessor.{Model, Repo}
  alias Model.User

  def edit(conn, _params, user, _claims) do
    changeset = User.update_vacation_changeset(user)
    render conn, "edit.html", changeset: changeset, user: user
  end

  def update(conn, %{"user" => user_params}, user, _claims) do
    changeset = User.update_vacation_changeset(user, user_params)

    case Repo.update(changeset) do
      {:ok, user} ->
        vacation_start = Calendar.Strftime.strftime!(user.vacation_start, "%B %e, %Y")
        vacation_end = Calendar.Strftime.strftime!(user.vacation_end, "%B %e, %Y")
        conn
        |> put_flash(:info, "Your alerts will be paused between #{vacation_start} and #{vacation_end}.")
        |> redirect(to: subscription_path(conn, :index))
      {:error, changeset} ->
        render conn, "edit.html", user: user, changeset: changeset
    end
  end

  def delete(conn, _params, user, _claims) do
    changeset = User.remove_vacation_period_changeset(user)

    case Repo.update(changeset) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "Your alerts are no longer paused.")
        |> redirect(to: subscription_path(conn, :index))
      {:error, _} ->
        conn
        |> put_flash(:error, "Something went wrong, please try again.")
        |> redirect(to: subscription_path(conn, :index))
    end
  end
end
