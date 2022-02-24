defmodule ConciergeSite.RejectedEmailController do
  use ConciergeSite.Web, :controller

  alias AlertProcessor.Model.User
  require Logger

  @ex_aws Application.compile_env!(:alert_processor, :ex_aws)

  def handle_message(conn, _params) do
    with {:ok, raw_body, conn} <- read_body(conn),
         {:ok, params} <- Poison.decode(raw_body),
         :ok <- @ex_aws.SNS.verify_message(params) do
      do_handle_message(params)
      send_resp(conn, :no_content, "")
    else
      {:more, partial_body, conn} ->
        log_error("event=handle_error reason=too_large #{partial_body}")
        send_resp(conn, :request_entity_too_large, "")

      {:error, {:invalid, _}} ->
        log_error("event=handle_error reason=invalid_json")
        send_resp(conn, :bad_request, "")

      {:error, error} ->
        log_error("event=handle_error reason=verify #{error}")
        send_resp(conn, :unauthorized, "")
    end
  end

  defp do_handle_message(%{"Type" => "SubscriptionConfirmation", "SubscribeURL" => url}) do
    {:ok, %{status_code: 200}} = HTTPoison.get(url)
    log_info("event=subscription_confirmation")
  end

  # No action required for these
  defp do_handle_message(%{"Type" => "UnsubscribeConfirmation"}),
    do: log_info("event=unsubscribe_confirmation")

  defp do_handle_message(%{"Type" => "Notification", "Message" => message_json}) do
    message = Poison.decode!(message_json)
    log_info("event=notification #{inspect(message)}")
    handle_notification(message)
  end

  defp handle_notification(%{"notificationType" => "Bounce", "bounce" => bounce}),
    do: handle_bounce(bounce)

  defp handle_notification(%{"notificationType" => "Complaint", "complaint" => complaint}),
    do: handle_complaint(complaint)

  # Since we only send emails to single recipients, assert that reports are only for a single
  # recipient. This is important for complaints, since if the list contains multiple recipients,
  # it's not guaranteed that complaints were actually received from all of them. See:
  # https://docs.aws.amazon.com/ses/latest/DeveloperGuide/notification-contents.html#complained-recipients

  defp handle_bounce(%{
         "bounceType" => "Permanent",
         "bouncedRecipients" => [%{"emailAddress" => email}]
       }) do
    with_user(email, fn user ->
      {:ok, _} = User.set_email_rejection(user, "bounce")
      log_info("event=user_opted_out reason=bounce email=#{email}")
    end)
  end

  # Take no action on other bounce types, but assert the type is one of the expected ones
  defp handle_bounce(%{"bounceType" => type}) when type in ~w(Transient Undetermined), do: nil

  defp handle_complaint(%{
         "complaintFeedbackType" => "not-spam",
         "complainedRecipients" => [%{"emailAddress" => email}]
       }) do
    with_user(email, fn user ->
      {:ok, _} = User.unset_email_rejection(user)
      log_info("event=user_opted_in email=#{email}")
    end)
  end

  defp handle_complaint(%{"complainedRecipients" => [%{"emailAddress" => email}]}) do
    with_user(email, fn user ->
      {:ok, _} = User.set_email_rejection(user, "complaint")
      log_info("event=user_opted_out reason=complaint email=#{email}")
    end)
  end

  defp with_user(email, func) do
    case User.for_email(email) do
      nil -> log_warn("event=user_not_found email=#{email}")
      user -> func.(user)
    end
  end

  defp log_error(message), do: Logger.error("#{__MODULE__} #{message}")
  defp log_info(message), do: Logger.info("#{__MODULE__} #{message}")
  defp log_warn(message), do: Logger.warn("#{__MODULE__} #{message}")
end
