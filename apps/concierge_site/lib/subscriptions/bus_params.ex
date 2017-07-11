defmodule ConciergeSite.Subscriptions.BusParams do
  @moduledoc """
  Functions for processing user input during the bus subscription flow
  """
  import ConciergeSite.Subscriptions.{ParamsValidator, SubscriptionParams}

  @spec validate_info_params(map) :: :ok | {:error, String.t}
  def validate_info_params(params) do
    {_, errors} =
      {params, []}
      |> validate_presence_of_route()
      |> validate_at_least_one_travel_day()

    if errors == [] do
      :ok
    else
      {:error, full_error_message_iodata(errors)}
    end
  end

  defp validate_presence_of_route({params, errors}) do
    if params["route"] == "" || params["route"] == nil do
      {params, ["Route is invalid." | errors]}
    else
      {params, errors}
    end
  end

  defp validate_at_least_one_travel_day({params, errors}) do
    day_params = [params["weekday"], params["saturday"], params["sunday"]]
    if !Enum.any?(day_params, &(&1 == "true")) do
      {params, ["At least one travel day option must be selected." | errors]}
    else
      {params, errors}
    end
  end

  @doc """
  Transform submitted subscription params for BusMapper
  """
  @spec prepare_for_mapper(map) :: map
  def prepare_for_mapper(%{"trip_type" => "one_way"} = params) do
    translated_params = %{
      "relevant_days" => relevant_days_from_booleans(Map.take(params, ~w(weekday saturday sunday))),
      "return_start" => nil,
      "return_end" => nil,
      "amenities" => []
    }

    params
    |> Map.take(["alert_priority_type", "departure_end", "departure_start", "route"])
    |> Map.merge(translated_params)
  end
  def prepare_for_mapper(%{"trip_type" => "round_trip"} = params) do
    translated_params = %{
      "relevant_days" => relevant_days_from_booleans(Map.take(params, ~w(weekday saturday sunday))),
      "amenities" => []
    }

    params
    |> Map.take(["alert_priority_type", "departure_end", "departure_start", "return_start", "return_end", "route"])
    |> Map.merge(translated_params)
  end
end
