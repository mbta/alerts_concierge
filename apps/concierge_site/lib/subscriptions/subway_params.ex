defmodule ConciergeSite.Subscriptions.SubwayParams do
  @moduledoc """
  Functions for processing user input during the create subway subscription flow
  """

  @spec validate_info_params(map) :: {:ok} | {:error, String.t}
  def validate_info_params(params) do
    {_, errors} =
    validate_presence_of_origin({params, []})
    |> validate_presence_of_destination()
    |> validate_at_least_one_travel_day()

    case errors do
      [] ->
        {:ok}
      errors ->
        {:error, full_error_message(errors)}
    end
  end

  defp validate_presence_of_origin({params, errors}) do
    case String.length(params["origin"]) do
      0 ->
        {params, ["Origin is invalid" | errors]}
      _ ->
        {params, errors}
    end
  end

  defp validate_presence_of_destination({params, errors}) do
    case String.length(params["destination"]) do
      0 ->
        {params, ["Destination is invalid" | errors]}
      _ ->
        {params, errors}
    end
  end

  defp validate_at_least_one_travel_day({params, errors}) do
    case {params["weekdays"], params["saturday"], params["sunday"]} do
      {"false", "false", "false"} ->
        {params, ["At least one travel day option must be selected" | errors]}
      _ ->
        {params, errors}
    end
  end

  defp full_error_message(errors) do
    "Please correct the following errors to proceed: #{Enum.join(errors, ", ") |> String.capitalize()}."
  end
end
