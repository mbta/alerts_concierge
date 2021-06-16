defmodule ConciergeSite.DigestFeedbackController do
  use ConciergeSite.Web, :controller
  alias ConciergeSite.DigestFeedback
  alias DigestFeedback.DigestRating, as: DigestRating
  alias DigestFeedback.DigestRatingReason, as: DigestRatingReason

  def feedback(conn, params) do
    case DigestFeedback.parse_digest_rating(params) do
      {:ok, %DigestRating{rating: rating} = digest_rating} ->
        DigestFeedback.log_digest_rating(digest_rating)
        template = if rating == "yes", do: "thanks.html", else: "form.html"
        render(conn, template)

      {:error, _error} ->
        render(conn, "error.html")
    end
  end

  def new(conn, params) do
    case DigestFeedback.parse_digest_rating_reason(params) do
      {:ok, %DigestRatingReason{} = digest_rating_reason} ->
        DigestFeedback.log_digest_rating_reason(digest_rating_reason)
        json(conn, %{status: "ok"})

      {:error, _error} ->
        json(conn, %{status: "error", error: "invalid input"})
    end
  end
end
