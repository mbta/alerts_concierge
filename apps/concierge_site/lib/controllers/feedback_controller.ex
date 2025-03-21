defmodule ConciergeSite.FeedbackController do
  use ConciergeSite.Web, :controller
  alias ConciergeSite.Feedback
  alias Feedback.AlertRating, as: AlertRating
  alias Feedback.AlertRatingReason, as: AlertRatingReason

  def feedback(conn, params) do
    case Feedback.parse_alert_rating(params) do
      {:ok, %AlertRating{rating: rating, user_id: user_id, alert_id: alert_id} = alert_rating} ->
        alert = Feedback.get_alert(alert_id)
        Feedback.log_alert_rating(alert, alert_rating)
        template = if rating == "yes", do: "thanks.html", else: "form.html"
        render(conn, template, alert_id: alert_id, user_id: user_id)

      {:error, _error} ->
        render(conn, "error.html")
    end
  end

  def new(conn, params) do
    case Feedback.parse_alert_rating_reason(params) do
      {:ok, %AlertRatingReason{alert_id: alert_id} = alert_rating_reason} ->
        alert = Feedback.get_alert(alert_id)
        Feedback.log_alert_rating_reason(alert, alert_rating_reason)
        json(conn, %{status: "ok"})

      {:error, _error} ->
        json(conn, %{status: "error", error: "invalid input"})
    end
  end
end
