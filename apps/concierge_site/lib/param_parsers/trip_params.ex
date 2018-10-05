defmodule ConciergeSite.ParamParsers.TripParams do
  @moduledoc """
  Helpers for sanitizing incoming trip parameters
  """
  alias ConciergeSite.ParamParsers.ParamTime

  @spec collate_facility_types(map, [String.t()]) :: map
  def collate_facility_types(params, valid_facility_types) do
    {facility_type_params, non_facility_type_params} = params |> Map.split(valid_facility_types)

    Map.merge(non_facility_type_params, %{
      "facility_types" => input_to_facility_types(facility_type_params, valid_facility_types)
    })
  end

  @spec input_to_facility_types(map, [String.t()]) :: [atom]
  def input_to_facility_types(params, valid_facility_types) do
    valid_facility_types
    |> Enum.reduce([], fn type, acc ->
      if params[type] == "true" do
        acc ++ [String.to_existing_atom(type)]
      else
        acc
      end
    end)
  end

  @spec sanitize_trip_params(map) :: map
  def sanitize_trip_params(trip_params) when is_map(trip_params),
    do: Map.new(trip_params, &sanitize_trip_param/1)

  @valid_time_keys ~w(start_time end_time return_start_time return_end_time alert_time)
  defp sanitize_trip_param({time_key, time_value}) when time_key in @valid_time_keys do
    {time_key, ParamTime.to_time(time_value)}
  end

  defp sanitize_trip_param({"relevant_days" = key, relevant_days}) do
    days_as_atoms = Enum.map(relevant_days, &String.to_existing_atom/1)
    {key, days_as_atoms}
  end

  defp sanitize_trip_param({"facility_types" = key, facility_types}), do: {key, facility_types}
end
