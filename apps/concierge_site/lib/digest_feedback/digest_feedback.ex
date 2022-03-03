defmodule ConciergeSite.DigestFeedback do
  @moduledoc """
  Feedback from users about an email digest that they received
  """
  require Logger
  import ConciergeSite.Feedback, only: [clean_string_for_splunk: 1]

  defmodule DigestRating do
    @moduledoc """
    How the user rated the digest
    """
    defstruct [
      :rating
    ]

    @type t :: %__MODULE__{
            rating: String.t()
          }
  end

  defmodule DigestRatingReason do
    @moduledoc """
    Freeform feedback on an digest from a user
    """
    defstruct [
      :why,
      :what
    ]

    @type t :: %__MODULE__{
            why: String.t(),
            what: String.t()
          }
  end

  @spec parse_digest_rating(map) :: {atom, DigestRating.t() | String.t()}
  def parse_digest_rating(%{"rating" => rating})
      when rating in ["yes", "no"] do
    {:ok,
     %DigestRating{
       rating: rating
     }}
  end

  def parse_digest_rating(_), do: {:error, "bad input"}

  @spec parse_digest_rating_reason(map) :: {atom, DigestRatingReason.t() | String.t()}
  def parse_digest_rating_reason(%{
        "what" => what,
        "why" => why
      }) do
    {:ok,
     %DigestRatingReason{
       what: what,
       why: why
     }}
  end

  def parse_digest_rating_reason(_), do: {:error, "bad input"}

  @spec log_digest_rating(DigestRating.t()) :: any
  def log_digest_rating(%DigestRating{rating: rating}) do
    Logger.info("digest-rating helpful=#{rating}")
  end

  def log_digest_rating(_), do: nil

  @spec log_digest_rating_reason(DigestRatingReason.t()) :: any

  def log_digest_rating_reason(%DigestRatingReason{what: what, why: why}) do
    Logger.info(
      "digest-reason " <>
        "what=\"#{clean_string_for_splunk(what)}\" why=\"#{clean_string_for_splunk(why)}\""
    )
  end

  def log_digest_rating_reason(_), do: nil
end
