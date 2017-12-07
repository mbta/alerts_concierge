defmodule ConciergeSite.Subscriptions.AccessibilityParams do
  @moduledoc false
  import ConciergeSite.Subscriptions.ParamsValidator

  @spec validate_info_params(map) :: :ok | {:error, String.t}
  def validate_info_params(params) do
    {_, errors} =
      {params, []}
      |> remove_empty_strings()
      |> validate_presence_of_accessibility()
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

  defp missing_stops?(%{"stops" => [stop | _]}) when not is_nil(stop), do: false
  defp missing_stops?(_), do: true

  defp missing_routes?(params) do
    Enum.empty?(params["routes"])
  end

  defp validate_presence_of_accessibility({params, errors}) do
    if Enum.empty?(params["accessibility"]) do
      {params, ["At least one accessibility must be selected." | errors]}
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
