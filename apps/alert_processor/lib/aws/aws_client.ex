defmodule AlertProcessor.Aws.AwsClient do
  @moduledoc """
  wrapper module for ExAws library to use mock implementation in
  test environment.
  """
  @ex_aws Application.get_env(:alert_processor, :ex_aws)

  @type response :: {:ok, map} | {:error, map} | {:error, String.t}

  @spec request(ExAws.Operation.Query.t, list | nil) :: response
  def request(operation, opts \\ []) do
    @ex_aws.request(operation, opts)
  end
end
