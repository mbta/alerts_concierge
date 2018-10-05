defmodule ConciergeSite.Feedback do
  alias AlertProcessor.Repo
  alias AlertProcessor.Model.SavedAlert
  require Logger

  defmodule AlertRating do
    defstruct [
      :alert_id,
      :user_id,
      :rating
    ]

    @type t :: %__MODULE__{
            alert_id: String.t(),
            user_id: String.t(),
            rating: String.t()
          }
  end

  defmodule AlertRatingReason do
    defstruct [
      :alert_id,
      :user_id,
      :why,
      :what
    ]

    @type t :: %__MODULE__{
            alert_id: String.t(),
            user_id: String.t(),
            why: String.t(),
            what: String.t()
          }
  end

  @spec parse_alert_rating(map) :: {atom, AlertRating.t() | String.t()}
  def parse_alert_rating(%{"alert_id" => alert_id, "user_id" => user_id, "rating" => rating})
      when rating in ["yes", "no"] do
    {:ok,
     %AlertRating{
       alert_id: alert_id,
       user_id: user_id,
       rating: rating
     }}
  end

  def parse_alert_rating(_), do: {:error, "bad input"}

  @spec parse_alert_rating_reason(map) :: {atom, AlertRatingReason.t() | String.t()}
  def parse_alert_rating_reason(%{
        "alert_id" => alert_id,
        "user_id" => user_id,
        "what" => what,
        "why" => why
      }) do
    {:ok,
     %AlertRatingReason{
       alert_id: alert_id,
       user_id: user_id,
       what: what,
       why: why
     }}
  end

  def parse_alert_rating_reason(_), do: {:error, "bad input"}

  @spec get_alert(String.t()) :: SavedAlert.t() | nil
  def get_alert(alert_id), do: Repo.get_by(SavedAlert, alert_id: alert_id)

  @spec log_alert_rating(nil | SavedAlert.t(), AlertRating.t()) :: any
  def log_alert_rating(nil, _), do: nil

  def log_alert_rating(alert, %AlertRating{rating: rating, user_id: user_id}) do
    Logger.info(
      Enum.join(
        ["feedback-rating"] ++
          ["helpful=#{rating} user_id=#{user_id}"] ++
          flatten_informed_entities(alert) ++ get_attributes_attributes(alert),
        " "
      )
    )
  end

  @spec log_alert_rating_reason(nil | SavedAlert.t(), AlertRatingReason.t()) :: any
  def log_alert_rating_reason(nil, _), do: nil

  def log_alert_rating_reason(alert, %AlertRatingReason{user_id: user_id, what: what, why: why}) do
    Logger.info(
      Enum.join(
        ["feedback-reason"] ++
          [
            "what=\"#{clean_string_for_splunk(what)}\" why=\"#{clean_string_for_splunk(why)}\" user_id=#{
              user_id
            }"
          ] ++ flatten_informed_entities(alert) ++ get_attributes_attributes(alert),
        " "
      )
    )
  end

  @spec get_attributes_attributes(SavedAlert.t()) :: [String.t()]
  defp get_attributes_attributes(alert) do
    [%{"text" => text}] = alert.data["header_text"]["translation"]

    [
      "alert_id=#{alert.alert_id} created=#{alert.data["created_timestamp"]} severity=#{
        alert.data["severity"]
      } text=\"#{clean_string_for_splunk(text)}\""
    ]
  end

  @spec clean_string_for_splunk(String.t()) :: String.t()
  defp clean_string_for_splunk(string) do
    string
    |> String.replace("\"", "'")
    |> String.replace("\r\n", " ")
    |> String.replace("\n", " ")
  end

  @spec flatten_informed_entities(SavedAlert.t()) :: [String.t()]
  defp flatten_informed_entities(%{data: %{"informed_entity" => informed_entity}}) do
    informed_entity
    |> Enum.reduce([], fn entity, acc ->
      route_type = if entity["route_type"], do: ["route_type=#{entity["route_type"]}"], else: []
      route_id = if entity["route_id"], do: ["route_id=#{entity["route_id"]}"], else: []
      stop_id = if entity["stop_id"], do: ["stop_id=#{entity["stop_id"]}"], else: []
      acc ++ route_type ++ route_id ++ stop_id
    end)
    |> Enum.sort()
    |> Enum.dedup()
  end
end
