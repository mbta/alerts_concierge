defmodule ConciergeSite.RejectedEmailController do
  use ConciergeSite.Web, :controller

  alias AlertProcessor.{Model.User, Repo}

  def handle_rejected_email(conn, params) do
    do_handle_rejected_email(conn, params)
  end

  def do_handle_rejected_email(conn, %{"notificationType" => "Bounce", "bounce" => params}) do
    put_users_in_vacation(params["bouncedRecipients"])
    conn
    |> put_status(:ok)
    |> json(%{})
  end
  def do_handle_rejected_email(conn, %{"notificationType" => "Complaint", "complaint" => params}) do
    put_users_in_vacation(params["complainedRecipients"])

    conn
    |> put_status(:ok)
    |> json(%{})
  end
  def do_handle_rejected_email(conn, _) do
    conn
    |> put_status(422)
    |> json(%{error: "invalid request"})
  end

  defp put_users_in_vacation(users) do
    users
    |> Enum.map(fn(user_data) ->
      user = Repo.get_by(User, email: user_data["emailAddress"])
      User.clear_holding_queue_for_user_id(user.id)
      User.put_user_on_indefinite_vacation(user)
    end)
  end
end
