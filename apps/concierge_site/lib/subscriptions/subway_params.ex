defmodule ConciergeSite.Subscriptions.SubwayParams do
  @moduledoc """
  Functions for processing user input during the create subway subscription flow
  """

  @spec validate_info_params(map) :: :ok | {:error, String.t}
  def validate_info_params(params) do
    {_, errors} =
      {params, []}
      |> validate_presence_of_origin()
      |> validate_presence_of_destination()
      |> validate_at_least_one_travel_day()

    case errors do
      [] ->
        :ok
      errors ->
        {:error, full_error_message(errors)}
    end
  end

  defp validate_presence_of_origin({params, errors}) do
    if params["origin"] == "" do
      {params, ["origin is invalid" | errors]}
    else
      {params, errors}
    end
  end

  defp validate_presence_of_destination({params, errors}) do
    if params["destination"] == "" do
      {params, ["destination is invalid" | errors]}
    else
      {params, errors}
    end
  end

  defp validate_at_least_one_travel_day({params, errors}) do
    if {params["weekdays"], params["saturday"], params["sunday"]} == {"false", "false", "false"} do
      {params, ["At least one travel day option must be selected" | errors]}
    else
      {params, errors}
    end
  end

  defp full_error_message(errors) do
    "Please correct the following errors to proceed: #{Enum.join(errors, ", ") |> String.capitalize()}."
  end
end
