defmodule ConciergeSite.ParamParsers.TripParamsTest do
  @moduledoc false
  use ExUnit.Case, async: true
  alias ConciergeSite.ParamParsers.TripParams

  test "collate_facility_types/2" do
    initial_params = %{
      "relevant_days" => ["tuesday", "thursday"],
      "bike_storage" => "true",
      "start_time" => "1:30 PM",
      "end_time" => "2:00 PM",
      "elevator" => "true",
      "return_start_time" => "3:30 PM",
      "return_end_time" => "4:00 PM",
      "parking_area" => "true"
    }

    valid_facility_types = ~w(bike_storage elevator)

    collated_params = TripParams.collate_facility_types(initial_params, valid_facility_types)

    assert collated_params == %{
             "relevant_days" => ["tuesday", "thursday"],
             "start_time" => "1:30 PM",
             "end_time" => "2:00 PM",
             "return_start_time" => "3:30 PM",
             "return_end_time" => "4:00 PM",
             "facility_types" => [:bike_storage, :elevator],
             "parking_area" => "true"
           }
  end

  test "input_to_facility_types/2" do
    params = %{
      "relevant_days" => ["tuesday", "thursday"],
      "bike_storage" => "true",
      "start_time" => "1:30 PM",
      "end_time" => "2:00 PM",
      "elevator" => "true",
      "return_start_time" => "3:30 PM",
      "return_end_time" => "4:00 PM",
      "parking_area" => "true"
    }

    valid_facility_types = ~w(bike_storage elevator)

    facility_types = TripParams.input_to_facility_types(params, valid_facility_types)

    assert facility_types == [:bike_storage, :elevator]
  end

  test "sanitize_trip_params" do
    intitial_params = %{
      "relevant_days" => ["tuesday", "thursday"],
      "start_time" => %{"am_pm" => "AM", "hour" => "6", "minute" => "30"},
      "end_time" => %{"am_pm" => "AM", "hour" => "9", "minute" => "0"},
      "return_start_time" => %{"am_pm" => "PM", "hour" => "4", "minute" => "15"},
      "return_end_time" => %{"am_pm" => "PM", "hour" => "8", "minute" => "0"},
      "facility_types" => [:bike_storage, :elevator]
    }

    sanitized_params = TripParams.sanitize_trip_params(intitial_params)

    assert sanitized_params == %{
             "relevant_days" => [:tuesday, :thursday],
             "start_time" => ~T[06:30:00],
             "end_time" => ~T[09:00:00],
             "return_start_time" => ~T[16:15:00],
             "return_end_time" => ~T[20:00:00],
             "facility_types" => [:bike_storage, :elevator]
           }
  end
end
