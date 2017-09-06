defmodule ConciergeSite.Subscriptions.AmenitiesParams do
  @moduledoc false
  import ConciergeSite.Subscriptions.ParamsValidator

  @spec validate_info_params(map) :: :ok | {:error, String.t}
  def validate_info_params(params) do
    {_, errors} =
      {params, []}
      |> remove_empty_strings()
      |> validate_presence_of_amenities()
      |> validate_at_least_one_travel_day()
      |> validate_at_least_one_station_or_line()

    if errors == [] do
      :ok
    else
      {:error, full_error_message_iodata(errors)}
    end
  end

  defp validate_at_least_one_station_or_line({params, errors}) do
    if missing_stops?(params) && missing_routes?(params) do
      {params, ["At least one station or line must be selected." | errors]}
    else
      {params, errors}
    end
  end

  defp missing_stops?(params) do
    params["stops"] == ""
  end

  defp missing_routes?(params) do
    Enum.empty?(params["routes"])
  end

  defp validate_presence_of_amenities({params, errors}) do
    if Enum.empty?(params["amenities"]) do
      {params, ["At least one amenity must be selected." | errors]}
    else
      {params, errors}
    end
  end

  defp validate_at_least_one_travel_day({params, errors}) do
    if Enum.empty?(params["relevant_days"]) do
      {params, ["At least one travel day must be selected." | errors]}
    else
      {params, errors}
    end
  end

  defp remove_empty_strings({params, errors}) do
    clean_params = Enum.reduce(params, %{}, fn({k, v}, acc) ->
      if is_list(v) do
        Map.put(acc, k, Enum.reject(v, & &1 == ""))
      else
        Map.put(acc, k, v)
      end
    end)
    {clean_params, errors}
  end
end
