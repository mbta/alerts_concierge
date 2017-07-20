defmodule ConciergeSite.Subscriptions.FerryParamsTest do
  use ExUnit.Case
  alias ConciergeSite.Subscriptions.FerryParams

  describe "validate_info_params" do
    test "it returns error messages when origin and destination are not on the same route" do
      params = %{
        "origin" => "Boat-Charlestown",
        "destination" => "Boat-Hull",
        "relevant_days" => "weekday",
        "departure_start" => "12:00:00",
        "departure_end" => "14:00:00",
        "return_start" => nil,
        "return_end" => nil
      }

      {:error, message} = FerryParams.validate_info_params(params)
      assert IO.iodata_to_binary(message) == "Please correct the following errors to proceed: Please select a valid origin and destination combination."
    end

    test "it returns ok when origin and destination are on the same route" do
      params = %{
        "origin" => "Boat-Long",
        "destination" => "Boat-Hingham",
        "relevant_days" => "saturday",
        "departure_start" => "12:00:00",
        "departure_end" => "14:00:00",
        "return_start" => nil,
        "return_end" => nil,
      }

      assert FerryParams.validate_info_params(params) == :ok
    end
  end

  describe "validate_trip_params" do
    test "returns an error message if a trip is not selected" do
      params = %{
        "trip_type" => "one_way"
      }

      {:error, message} = FerryParams.validate_trip_params(params)
      assert IO.iodata_to_binary(message) == "Please correct the following errors to proceed: Please select at least one trip."
    end

    test "returns an error if a return trip is not selected" do
      params = %{
        "trip_type" => "round_trip",
        "trips" => ["123"]
      }

      {:error, message} = FerryParams.validate_trip_params(params)
      assert IO.iodata_to_binary(message) == "Please correct the following errors to proceed: Please select at least one return trip."
    end

    test "returns an error if neither are selected" do
      params = %{
        "trip_type" => "round_trip"
      }

      {:error, message} = FerryParams.validate_trip_params(params)
      assert IO.iodata_to_binary(message) == "Please correct the following errors to proceed: Please select at least one return trip. Please select at least one trip."
    end

    test "returns ok if at least one trip is selected" do
      params = %{
        "trip_type" => "one_way",
        "trips" => ["123"]
      }

      assert :ok = FerryParams.validate_trip_params(params)
    end

    test "returns ok if at least one trip and return trip are selected" do
      params = %{
        "trip_type" => "round_trip",
        "trips" => ["123"],
        "return_trips" => ["456"]
      }

      assert :ok = FerryParams.validate_trip_params(params)
    end
  end

  describe "prepare_for_mapper one_way" do
    @params %{
      "alert_priority_type" => "low",
      "departure_start" => "09:00:00",
      "destination" => "Boat-Long",
      "origin" => "Boat-Hingham",
      "relevant_days" => "weekday",
      "route_type" => "4",
      "trip_type" => "one_way",
      "trips" => ["Boat-F1-Boat-Hingham-06:40:00-weekday-1"],
      "user_id" => "123-456-7890"
    }

    test "it preps params for one way parameters" do
      assert FerryParams.prepare_for_mapper(@params) == Map.merge(@params, %{
        "amenities" => [],
        "departure_start" => ~T[10:40:00],
        "departure_end" => ~T[11:23:00],
        "relevant_days" => ["weekday"],
        "return_start" => nil,
        "return_end" => nil
      })
    end

    test "it adjusts the actual departure_start and departure_end timestamps based on trips selected" do
      assert %{"departure_start" => ~T[10:40:00], "departure_end" => ~T[11:23:00]} = FerryParams.prepare_for_mapper(@params)
    end

    test "it transform single relevant days value into array with same value" do
      assert %{"relevant_days" => ["weekday"]} = FerryParams.prepare_for_mapper(@params)
    end

    test "it sets return_start and return_end to nil" do
      assert %{"return_start" => nil, "return_end" => nil} = FerryParams.prepare_for_mapper(@params)
    end
  end

  describe "prepare_for_mapper round_trip" do
    @params %{
      "alert_priority_type" => "low",
      "departure_start" => "09:00:00",
      "destination" => "Boat-Long",
      "origin" => "Boat-Hingham",
      "relevant_days" => "weekday",
      "return_start" => "14:00:00",
      "return_trips" => ["Boat-F1-Boat-Long-21:10:00-weekday-0"],
      "route_type" => "4",
      "trip_type" => "round_trip",
      "trips" => ["Boat-F1-Boat-Hingham-10:00:00-weekday-1", "Boat-F1-Boat-Hingham-12:00:00-weekday-1"],
      "user_id" => "123-456-7890"
    }

    test "it preps params for round trip parameters" do
      assert FerryParams.prepare_for_mapper(@params) == Map.merge(@params, %{
        "amenities" => [],
        "departure_start" => ~T[14:00:00],
        "departure_end" => ~T[16:55:00],
        "relevant_days" => ["weekday"],
        "return_start" => ~T[01:10:00],
        "return_end" => ~T[02:05:00]
      })
    end

    test "it adjusts the actual departure_start and departure_end timestamps based on trips selected" do
      assert %{"departure_start" => ~T[14:00:00], "departure_end" => ~T[16:55:00]} = FerryParams.prepare_for_mapper(@params)
    end

    test "it transform single relevant days value into array with same value" do
      assert %{"relevant_days" => ["weekday"]} = FerryParams.prepare_for_mapper(@params)
    end

    test "it sets return_start and return_end to nil" do
      assert %{"return_start" => ~T[01:10:00], "return_end" => ~T[02:05:00]} = FerryParams.prepare_for_mapper(@params)
    end
  end
end
