defmodule AlertProcessor.Aws.AwsClient do
  @moduledoc "Wrapper for ExAws allowing it to be mocked in the test environment."

  @ex_aws Application.get_env(:alert_processor, :ex_aws)

  def request(operation, config_overrides \\ []), do: @ex_aws.request(operation, config_overrides)
end
