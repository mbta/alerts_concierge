defmodule ConciergeSite.Subscriptions.BusParamsTest do
  use ExUnit.Case
  alias ConciergeSite.Subscriptions.BusParams

  describe "validate_info_params" do
    test "it returns error messages when route not present" do
      params = %{
        "route" => "",
        "weekday" => "true",
        "departure_start" => "12:00:00",
        "departure_end" => "14:00:00",
        "trip_type" => "one_way"
      }

      {:error, message} = BusParams.validate_info_params(params)
      assert IO.iodata_to_binary(message) == "Please correct the following errors to proceed: Route is invalid."
    end

    test "it returns error messages when route nil" do
      params = %{
        "weekday" => "true",
        "departure_start" => "12:00:00",
        "departure_end" => "14:00:00",
        "trip_type" => "one_way"
      }

      {:error, message} = BusParams.validate_info_params(params)
      assert IO.iodata_to_binary(message) == "Please correct the following errors to proceed: Route is invalid."
    end

    test "it returns error messages when a relevant day option is not selected" do
      params = %{
        "route" => "88 - 0",
        "departure_start" => "12:00:00",
        "departure_end" => "14:00:00",
        "trip_type" => "one_way"
      }

      {:error, message} = BusParams.validate_info_params(params)
      assert IO.iodata_to_binary(message) == "Please correct the following errors to proceed: At least one travel day option must be selected."
    end

    test "it returns ok when route and relevant day(s) are selected" do
      params = %{
        "route" => "88 - 0",
        "weekday" => "true",
        "saturday" => "true",
        "departure_start" => "12:00:00",
        "departure_end" => "14:00:00",
        "trip_type" => "one_way"
      }

      assert BusParams.validate_info_params(params) == :ok
    end
  end

  describe "prepare_for_mapper one_way" do
    test "converts relevant day options to array" do
      params = %{
        "route" => "88 - 0",
        "weekday" => "true",
        "departure_start" => "12:00:00",
        "departure_end" => "13:00:00",
        "trip_type" => "one_way"
      }

      assert %{
        "relevant_days" => ["weekday"]
      } = BusParams.prepare_for_mapper(params)
    end

    test "sets return timeframe to nil" do
      params = %{
        "route" => "88 - 0",
        "sunday" => "true",
        "departure_start" => "12:00:00",
        "departure_end" => "13:00:00",
        "trip_type" => "one_way"
      }

      assert %{
        "route" => "88 - 0",
        "departure_start" => ds,
        "departure_end" => de,
        "return_start" => nil,
        "return_end" => nil,
        "relevant_days" => ["sunday"]
      } = BusParams.prepare_for_mapper(params)
      assert DateTime.to_time(ds) == ~T[16:00:00]
      assert DateTime.to_time(de) == ~T[17:00:00]
    end
  end

  describe "prepare_for_mapper round_trip" do
    test "converts relevant day options to array" do
      params = %{
        "route" => "88 - 0",
        "saturday" => "true",
        "departure_start" => "12:00:00",
        "departure_end" => "13:00:00",
        "return_start" => "18:00:00",
        "return_end" => "19:00:00",
        "trip_type" => "round_trip"
      }

      assert %{
        "route" => "88 - 0",
        "departure_start" => ds,
        "departure_end" => de,
        "return_start" => rs,
        "return_end" => re,
        "relevant_days" => ["saturday"]
      } = BusParams.prepare_for_mapper(params)
      assert DateTime.to_time(ds) == ~T[16:00:00]
      assert DateTime.to_time(de) == ~T[17:00:00]
      assert DateTime.to_time(rs) == ~T[22:00:00]
      assert DateTime.to_time(re) == ~T[23:00:00]
    end
  end
end
