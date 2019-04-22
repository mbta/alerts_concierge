defmodule ConciergeSite.RejectedEmailController do
  use ConciergeSite.Web, :controller

  alias AlertProcessor.Model.User
  require Logger

  def handle_rejected_email(conn, params) do
    do_handle_rejected_email(conn, params)
  end

  defp do_handle_rejected_email(conn, %{"notificationType" => "Bounce", "bounce" => params}) do
    log_rejected_email(params["bouncedRecipients"])

    conn
    |> put_status(:ok)
    |> json(%{})
  end

  defp do_handle_rejected_email(conn, %{"notificationType" => "Complaint", "complaint" => params}) do
    log_rejected_email(params["complainedRecipients"])

    conn
    |> put_status(:ok)
    |> json(%{})
  end

  defp log_rejected_email(users) do
    Enum.map(users, fn user_data ->
      case User.for_email(user_data["emailAddress"]) do
        nil ->
          :ok

        user ->
          Logger.info(fn -> "Rejected Email: #{user.id}" end)
      end
    end)
  end
end
