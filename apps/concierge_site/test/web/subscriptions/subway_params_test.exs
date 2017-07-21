defmodule ConciergeSite.Subscriptions.SubwayParamsTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  alias ConciergeSite.Subscriptions.SubwayParams

  describe "validate_info_params" do
    test "it returns error messages when origin and destination are not on the same Subway line" do
      use_cassette "subway_schedules_invalid", custom: true, clear_mock: true, match_requests_on: [:query] do
        params = %{
          "departure_start" => "08:45 AM",
          "departure_end" => "09:15 AM",
          "origin" => "place-brntn",
          "destination" => "place-asmnl",
          "saturday" => "false",
          "sunday" => "false",
          "weekday" => "true",
          "trip_type" => "one_way",
        }

        {:error, message} = SubwayParams.validate_info_params(params)

        assert IO.iodata_to_binary(message) == "Please correct the following errors to proceed: Origin and destination must be on the same line."
      end
    end

    test "it returns ok when origin and destination are on the same line" do
      use_cassette "subway_schedules", custom: true, clear_mock: true, match_requests_on: [:query] do
        params = %{
          "departure_start" => "08:45 AM",
          "departure_end" => "09:15 AM",
          "origin" => "place-brntn",
          "destination" => "place-qamnl",
          "saturday" => "false",
          "sunday" => "false",
          "weekday" => "true",
          "trip_type" => "one_way",
        }

        assert SubwayParams.validate_info_params(params) == :ok
      end
    end
  end

  describe "prepare_for_mapper" do
    test "it changes selected travel days into a list of relevant days" do
      subscription_params = %{
        "weekday" => "true",
        "saturday" => "true",
        "sunday" => "true",
        "alert_priority_type" => "low",
        "departure_end" => "09:15:00",
        "departure_start" => "08:45:00",
        "destination" => "place-dwnxg",
        "origin" => "place-chmnl",
        "return_end" => "17:15:00",
        "return_start" => "16:45:00",
        "trip_type" => "round_trip"
      }

      mapped_params = SubwayParams.prepare_for_mapper(subscription_params)

      assert mapped_params["relevant_days"] == ["saturday", "sunday", "weekday"]
    end

    test "it adds a roaming key with the value true when the trip_type is roaming" do
      subscription_params = %{
        "weekday" => "true",
        "saturday" => "true",
        "sunday" => "true",
        "alert_priority_type" => "low",
        "departure_end" => "09:15:00",
        "departure_start" => "08:45:00",
        "destination" => "place-dwnxg",
        "origin" => "place-chmnl",
        "trip_type" => "roaming"
      }

      mapped_params = SubwayParams.prepare_for_mapper(subscription_params)

      assert mapped_params["roaming"] == "true"
    end

    test "it adds a roaming key with the value true when the trip_type is not roaming" do
      subscription_params = %{
        "weekday" => "true",
        "saturday" => "true",
        "sunday" => "true",
        "alert_priority_type" => "low",
        "departure_end" => "09:15:00",
        "departure_start" => "08:45:00",
        "destination" => "place-dwnxg",
        "origin" => "place-chmnl",
        "return_end" => "17:15:00",
        "return_start" => "16:45:00",
        "trip_type" => "round_trip"
      }

      mapped_params = SubwayParams.prepare_for_mapper(subscription_params)

      assert mapped_params["roaming"] == "false"
    end

    test "it maps params properly for one_way" do
      subscription_params = %{
        "weekday" => "false",
        "saturday" => "true",
        "sunday" => "false",
        "alert_priority_type" => "low",
        "departure_end" => "09:15:00",
        "departure_start" => "08:45:00",
        "destination" => "place-dwnxg",
        "origin" => "place-chmnl",
        "trip_type" => "one_way"
      }

      assert %{
        "amenities" => [],
        "alert_priority_type" => "low",
        "departure_start" => ds,
        "departure_end" => de,
        "return_start" => nil,
        "return_end" => nil,
        "roaming" => "false",
        "relevant_days" => ["saturday"],
        "origin" => "place-chmnl",
        "destination" => "place-dwnxg"
      } = SubwayParams.prepare_for_mapper(subscription_params)
      assert DateTime.to_time(ds) == ~T[12:45:00]
      assert DateTime.to_time(de) == ~T[13:15:00]
    end

    test "it maps params properly for round_trip" do
      subscription_params = %{
        "weekday" => "true",
        "saturday" => "false",
        "sunday" => "false",
        "alert_priority_type" => "low",
        "departure_end" => "09:15:00",
        "departure_start" => "08:45:00",
        "return_end" => "17:15:00",
        "return_start" => "16:45:00",
        "destination" => "place-dwnxg",
        "origin" => "place-chmnl",
        "trip_type" => "round_trip"
      }

      assert %{
        "amenities" => [],
        "alert_priority_type" => "low",
        "departure_start" => ds,
        "departure_end" => de,
        "return_start" => rs,
        "return_end" => re,
        "roaming" => "false",
        "relevant_days" => ["weekday"],
        "origin" => "place-chmnl",
        "destination" => "place-dwnxg"
      } = SubwayParams.prepare_for_mapper(subscription_params)
      assert DateTime.to_time(ds) == ~T[12:45:00]
      assert DateTime.to_time(de) == ~T[13:15:00]
      assert DateTime.to_time(rs) == ~T[20:45:00]
      assert DateTime.to_time(re) == ~T[21:15:00]
    end

    test "it maps params properly for roaming" do
      subscription_params = %{
        "weekday" => "false",
        "saturday" => "false",
        "sunday" => "true",
        "alert_priority_type" => "low",
        "departure_end" => "09:15:00",
        "departure_start" => "08:45:00",
        "destination" => "place-dwnxg",
        "origin" => "place-chmnl",
        "trip_type" => "roaming"
      }

      assert %{
        "amenities" => [],
        "alert_priority_type" => "low",
        "departure_start" => ds,
        "departure_end" => de,
        "return_start" => nil,
        "return_end" => nil,
        "roaming" => "true",
        "relevant_days" => ["sunday"],
        "origin" => "place-chmnl",
        "destination" => "place-dwnxg"
      } = SubwayParams.prepare_for_mapper(subscription_params)
      assert DateTime.to_time(ds) == ~T[12:45:00]
      assert DateTime.to_time(de) == ~T[13:15:00]
    end
  end
end
