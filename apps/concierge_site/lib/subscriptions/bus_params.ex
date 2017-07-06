defmodule ConciergeSite.Subscriptions.BusParams do
  @moduledoc """
  Functions for processing user input during the bus subscription flow
  """
  alias AlertProcessor.Helpers.DateTimeHelper

  @spec validate_info_params(map) :: :ok | {:error, String.t}
  def validate_info_params(params) do
    {_, errors} =
      {params, []}
      |> validate_presence_of_route()
      |> validate_at_least_one_travel_day()

    if errors == [] do
      :ok
    else
      {:error, full_error_message(errors)}
    end
  end

  defp validate_presence_of_route({params, errors}) do
    if params["route_id"] == "" do
      {params, ["Route is invalid" | errors]}
    else
      {params, errors}
    end
  end

  defp validate_at_least_one_travel_day({params, errors}) do
    day_params = [params["weekday"], params["saturday"], params["sunday"]]
    if !Enum.any?(day_params, &(&1 == "true")) do
      {params, ["At least one travel day option must be selected" | errors]}
    else
      {params, errors}
    end
  end

  defp full_error_message(errors) do
    [
      "Please correct the following errors to proceed: ",
      errors |> Enum.intersperse(". ")
    ]
  end

  @spec prepare_for_update_changeset(map) :: map
  def prepare_for_update_changeset(params) do
    relevant_days =
      params
      |> Map.take(~w(saturday sunday weekday))
      |> relevant_days_from_booleans()
      |> Enum.map(&String.to_existing_atom/1)

    %{"alert_priority_type" => String.to_existing_atom(params["alert_priority_type"]),
      "relevant_days" => relevant_days,
      "end_time" => DateTimeHelper.timestamp_to_utc(params["departure_end"]),
      "start_time" => DateTimeHelper.timestamp_to_utc(params["departure_start"])}
  end

  defp relevant_days_from_booleans(day_map) do
    day_map
    |> Enum.filter(fn {_day, bool} -> bool == "true" end)
    |> Enum.map(fn {day, _bool} -> day end)
  end
end
