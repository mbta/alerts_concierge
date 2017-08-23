defmodule ConciergeSite.VacationController do
  use ConciergeSite.Web, :controller
  use Guardian.Phoenix.Controller
  alias ConciergeSite.UserParams
  alias AlertProcessor.Model.User

  def edit(conn, _params, user, _claims) do
    changeset = User.update_vacation_changeset(user)
    render conn, "edit.html", changeset: changeset, user: user
  end

  def update(conn, %{"user" => user_params}, user, {:ok, claims}) do
    case UserParams.convert_vacation_strings_to_datetimes(user_params) do
      {:ok, vacation_dates} ->
        case User.update_vacation(user, vacation_dates, Map.get(claims, "imp", user.id)) do
          {:ok, user} ->
            vacation_start = Calendar.Strftime.strftime!(user.vacation_start, "%B %e, %Y")
            vacation_end = Calendar.Strftime.strftime!(user.vacation_end, "%B %e, %Y")
            :ok = User.clear_holding_queue_for_user_id(user.id)
            conn
            |> put_flash(:info, "Your alerts will be paused between #{vacation_start} and #{vacation_end}.")
            |> redirect(to: subscription_path(conn, :index))
          {:error, changeset} ->
            render conn, "edit.html", user: user, changeset: changeset
        end
      :error ->
        changeset = User.update_vacation_changeset(user, user_params)
        conn
        |> put_flash(:error, "Unable to pause alerts. Dates must match MM/DD/YYYY format.")
        |> render("edit.html", changeset: changeset, user: user)
    end
  end

  def delete(conn, _params, user, {:ok, claims}) do
    with {:ok, _} <- User.opt_in_phone_number(user),
      {:ok, _user} <- User.remove_vacation(user, Map.get(claims, "imp", user.id)) do
        conn
        |> put_flash(:info, "Your alerts are no longer paused.")
        |> redirect(to: subscription_path(conn, :index))
    else
      _ ->
        conn
        |> put_flash(:error, "Something went wrong, please try again.")
        |> redirect(to: subscription_path(conn, :index))
    end
  end
end
