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

      assert message == "Please correct the following errors to proceed: Please select a valid origin and destination combination."
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
end
