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

  describe "prepare_for_mapper one_way" do
    @params %{
      "alert_priority_type" => "low",
      "departure_start" => "09:00:00",
      "destination" => "Fairmount",
      "origin" => "Morton Street",
      "relevant_days" => "weekday",
      "route_type" => "2",
      "trip_type" => "one_way",
      "trips" => ["755", "757", "759"],
      "user_id" => "123-456-7890"
    }

    test "it preps params for one way parameters" do
      assert CommuterRailParams.prepare_for_mapper(@params) == Map.merge(@params, %{
        "amenities" => [],
        "departure_start" => ~T[12:21:00],
        "departure_end" => ~T[14:10:00],
        "relevant_days" => ["weekday"],
        "return_start" => nil,
        "return_end" => nil
      })
    end

    test "it adjusts the actual departure_start and departure_end timestamps based on trips selected" do
      assert %{"departure_start" => ~T[12:21:00], "departure_end" => ~T[14:10:00]} = CommuterRailParams.prepare_for_mapper(@params)
    end

    test "it transform single relevant days value into array with same value" do
      assert %{"relevant_days" => ["weekday"]} = CommuterRailParams.prepare_for_mapper(@params)
    end

    test "it sets return_start and return_end to nil" do
      assert %{"return_start" => nil, "return_end" => nil} = CommuterRailParams.prepare_for_mapper(@params)
    end
  end

  describe "prepare_for_mapper round_trip" do
    @params %{
      "alert_priority_type" => "low",
      "departure_start" => "09:00:00",
      "destination" => "Fairmount",
      "origin" => "Morton Street",
      "relevant_days" => "weekday",
      "return_start" => "14:00:00",
      "return_trips" => ["768"],
      "route_type" => "2",
      "trip_type" => "round_trip",
      "trips" => ["755", "757", "759"],
      "user_id" => "123-456-7890"
    }

    test "it preps params for round trip parameters" do
      assert CommuterRailParams.prepare_for_mapper(@params) == Map.merge(@params, %{
        "amenities" => [],
        "departure_start" => ~T[12:21:00],
        "departure_end" => ~T[14:10:00],
        "relevant_days" => ["weekday"],
        "return_start" => ~T[18:43:00],
        "return_end" => ~T[18:48:00]
      })
    end

    test "it adjusts the actual departure_start and departure_end timestamps based on trips selected" do
      assert %{"departure_start" => ~T[12:21:00], "departure_end" => ~T[14:10:00]} = CommuterRailParams.prepare_for_mapper(@params)
    end

    test "it transform single relevant days value into array with same value" do
      assert %{"relevant_days" => ["weekday"]} = CommuterRailParams.prepare_for_mapper(@params)
    end

    test "it sets return_start and return_end to correct times" do
      assert %{"return_start" => ~T[18:43:00], "return_end" => ~T[18:48:00]} = CommuterRailParams.prepare_for_mapper(@params)
    end
  end
end
