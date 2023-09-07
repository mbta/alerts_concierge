defmodule AlertProcessor.Aws.AwsClient do
  @moduledoc "Wrapper for ExAws allowing it to be mocked in the test environment."

  require Logger

  def request(operation, config_overrides \\ []),
    do: ex_aws().request(operation, config_overrides)

  @spec ex_aws :: module()
  defp ex_aws do
    mod = Application.get_env(:alert_processor, :ex_aws)
    Logger.info("Using ex_aws module #{mod}")
    mod
  end
end
