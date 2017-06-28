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

        assert message == "Please correct the following errors to proceed: Origin and destination must be on the same line."
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
end
