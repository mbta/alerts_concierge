defmodule ConciergeSite.FeedbackController do
  use ConciergeSite.Web, :controller
  alias ConciergeSite.Feedback
  alias Feedback.AlertRating, as: AlertRating
  alias Feedback.AlertRatingReason, as: AlertRatingReason

  def feedback(conn, params) do
    with {:ok, %AlertRating{rating: rating, user_id: user_id, alert_id: alert_id}} <-
           Feedback.parse_alert_rating(params) do
      alert = Feedback.get_alert(alert_id)
      Feedback.log_alert_rating(alert, user_id, rating)

      template = if rating == "yes", do: "thanks.html", else: "form.html"
      render(conn, template, alert_id: alert_id, user_id: user_id)
    else
      {:error, _error} ->
        render(conn, "error.html")
    end
  end

  def new(conn, params) do
    with {:ok, %AlertRatingReason{user_id: user_id, alert_id: alert_id, why: why, what: what}} <-
           Feedback.parse_alert_rating_reason(params) do
      alert = Feedback.get_alert(alert_id)
      Feedback.log_alert_rating_reason(alert, user_id, what, why)

      json(conn, %{status: "ok"})
    else
      {:error, _error} ->
        json(conn, %{status: "error", error: "invalid input"})
    end
  end
end
