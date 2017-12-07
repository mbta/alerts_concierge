defmodule ConciergeSite.Subscriptions.AccessibilityParamsTest do
  use ExUnit.Case
  alias ConciergeSite.Subscriptions.AccessibilityParams

  @valid_params %{
    "accessibility" => ["elevator"],
    "stops" => "North Station,South Station",
    "routes" => ["red"],
    "relevant_days" => ["weekday"]
  }

  describe "validate_info_params/1" do
    test "with valid params" do
      assert AccessibilityParams.validate_info_params(@valid_params) == :ok
    end

    test "handles empty strings" do
      params = Map.put(@valid_params, "relevant_days", ["", "", ""])

      assert {:error, _} = AccessibilityParams.validate_info_params(params)
    end

    test "errors if no travel days selected" do
      params = Map.put(@valid_params, "relevant_days", [])
      messages = ["Please correct the following errors to proceed: ", ["At least one travel day must be selected."]]

      assert AccessibilityParams.validate_info_params(params) == {:error, messages}
    end

    test "errors if no accessibility selected" do
      params = Map.put(@valid_params, "accessibility", [])
      messages = ["Please correct the following errors to proceed: ", ["At least one accessibility must be selected."]]

      assert AccessibilityParams.validate_info_params(params) == {:error, messages}
    end

    test "errors if no stations AND no subway lines selected" do
      params =
        @valid_params
        |> Map.put("routes", [])
        |> Map.put("stops", "")
      messages = ["Please correct the following errors to proceed: ", ["At least one station or line must be selected."]]

      assert AccessibilityParams.validate_info_params(params) == {:error, messages}
    end
  end
end
