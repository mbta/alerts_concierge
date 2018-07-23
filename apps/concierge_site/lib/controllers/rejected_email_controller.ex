defmodule ConciergeSite.RejectedEmailController do
  use ConciergeSite.Web, :controller

  alias AlertProcessor.Model.User
  require Logger

  def handle_rejected_email(conn, params) do
    do_handle_rejected_email(conn, params)
  end

  defp do_handle_rejected_email(conn, %{"notificationType" => "Bounce", "bounce" => params}) do
    put_users_in_vacation(params["bouncedRecipients"])

    conn
    |> put_status(:ok)
    |> json(%{})
  end

  defp do_handle_rejected_email(conn, %{"notificationType" => "Complaint", "complaint" => params}) do
    put_users_in_vacation(params["complainedRecipients"])

    conn
    |> put_status(:ok)
    |> json(%{})
  end

  defp put_users_in_vacation(users) do
    Enum.map(users, fn user_data ->
      case User.for_email(user_data["emailAddress"]) do
        nil ->
          :ok

        user ->
          Logger.info(fn -> "Rejected Email: #{inspect(user)} #{inspect(user_data)}" end)
          User.put_user_on_indefinite_vacation(user, "email-complaint-received")
      end
    end)
  end
end
