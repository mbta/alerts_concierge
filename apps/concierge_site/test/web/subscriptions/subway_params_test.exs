defmodule ConciergeSite.Subscriptions.SubwayParamsTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  alias ConciergeSite.Subscriptions.SubwayParams

  describe "validate_info_params" do
    test "it returns error messages when origin and destination are not on the same Subway line" do
      use_cassette "subway_schedules", custom: true, clear_mock: true, match_requests_on: [:query] do
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
        "return_end" => "17:15:00",
        "return_start" => "16:45:00",
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
  end

  describe "prepare_for_update_changeset" do
    test "it converts revelant days to a list of atoms" do
      params = %{
        "alert_priority_type" => "high",
        "departure_end" => "23:15:00",
        "departure_start" => "23:00:00",
        "saturday" => "true",
        "sunday" => "true",
        "weekday" => "true"
      }

      update_params = SubwayParams.prepare_for_update_changeset(params)

      assert update_params["relevant_days"] == [:saturday, :sunday, :weekday]
    end

    test "it converts departure_start and departure_end to start_time and end_time" do
      params = %{
        "alert_priority_type" => "high",
        "departure_end" => "23:15:00",
        "departure_start" => "23:00:00",
        "saturday" => "true",
        "sunday" => "true",
        "weekday" => "true"
      }

      update_params = SubwayParams.prepare_for_update_changeset(params)

      assert update_params["start_time"] == "23:00:00"
      assert update_params["end_time"] == "23:15:00"
    end

    test "it converts alert_priority_type to an atom" do
      params = %{
        "alert_priority_type" => "high",
        "departure_end" => "23:15:00",
        "departure_start" => "23:00:00",
        "saturday" => "true",
        "sunday" => "true",
        "weekday" => "true"
      }

      update_params = SubwayParams.prepare_for_update_changeset(params)

      assert update_params["alert_priority_type"] == :high
    end
  end
end
