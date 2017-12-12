defmodule ConciergeSite.Subscriptions.BikeStorageParamsTest do
  use ExUnit.Case
  alias ConciergeSite.Subscriptions.BikeStorageParams

  @valid_params %{
    "stops" => ["place-north"],
    "relevant_days" => ["weekday"]
  }

  describe "validate_info_params/1" do
    test "with valid params" do
      assert BikeStorageParams.validate_info_params(@valid_params) == :ok
    end

    test "handles empty strings" do
      params = Map.put(@valid_params, "relevant_days", ["", "", ""])

      assert {:error, _} = BikeStorageParams.validate_info_params(params)
    end

    test "errors if no travel days selected" do
      params = Map.put(@valid_params, "relevant_days", [])
      messages = ["Please correct the following errors to proceed: ", ["At least one travel day must be selected."]]

      assert BikeStorageParams.validate_info_params(params) == {:error, messages}
    end

    test "errors if no stations AND no subway lines selected" do
      params =
        @valid_params
        |> Map.put("stops", "")
      messages = ["Please correct the following errors to proceed: ", ["At least one station must be selected."]]

      assert BikeStorageParams.validate_info_params(params) == {:error, messages}
    end
  end
end
