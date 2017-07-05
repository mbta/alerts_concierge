defmodule ConciergeSite.Subscriptions.CommuterRailParamsTest do
  use ExUnit.Case
  alias ConciergeSite.Subscriptions.CommuterRailParams

  describe "validate_info_params" do
    test "it returns error messages when origin and destination are not on the same Subway line" do
      params = %{
        "origin" => "Anderson/ Woburn",
        "destination" => "place-south",
        "relevant_days" => "weekday",
        "departure_start" => "12:00:00",
        "departure_end" => "14:00:00",
        "return_start" => nil,
        "return_end" => nil
      }

      {:error, message} = CommuterRailParams.validate_info_params(params)
      assert IO.iodata_to_binary(message) == "Please correct the following errors to proceed: Please select a valid origin and destination combination."
    end

    test "it returns ok when origin and destination are on the same line" do
      params = %{
        "origin" => "Anderson/ Woburn",
        "destination" => "place-north",
        "relevant_days" => "saturday",
        "departure_start" => "12:00:00",
        "departure_end" => "14:00:00",
        "return_start" => nil,
        "return_end" => nil,
      }

      assert CommuterRailParams.validate_info_params(params) == :ok
    end
  end

  describe "validate_trip_params" do
    test "returns an error message if a trip is not selected" do
      params = %{
        "trip_type" => "one_way"
      }

      {:error, message} = CommuterRailParams.validate_trip_params(params)
      assert IO.iodata_to_binary(message) == "Please correct the following errors to proceed: Please select at least one trip."
    end

    test "returns an error if a return trip is not selected" do
      params = %{
        "trip_type" => "round_trip",
        "trips" => ["123"]
      }

      {:error, message} = CommuterRailParams.validate_trip_params(params)
      assert IO.iodata_to_binary(message) == "Please correct the following errors to proceed: Please select at least one return trip."
    end

    test "returns an error if neither are selected" do
      params = %{
        "trip_type" => "round_trip"
      }

      {:error, message} = CommuterRailParams.validate_trip_params(params)
      assert IO.iodata_to_binary(message) == "Please correct the following errors to proceed: Please select at least one return trip. Please select at least one trip."
    end

    test "returns ok if at least one trip is selected" do
      params = %{
        "trip_type" => "one_way",
        "trips" => ["123"]
      }

      assert :ok = CommuterRailParams.validate_trip_params(params)
    end

    test "returns ok if at least one trip and return trip are selected" do
      params = %{
        "trip_type" => "round_trip",
        "trips" => ["123"],
        "return_trips" => ["456"]
      }

      assert :ok = CommuterRailParams.validate_trip_params(params)
    end
  end
end
