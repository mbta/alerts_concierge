defmodule AlertProcessor.Aws.AwsClient do
  @moduledoc """
  wrapper module for ExAws library to use mock implementation in
  test environment.
  """
  @ex_aws Application.get_env(:alert_processor, :ex_aws)

  @type aws_success :: {:ok, map}
  @type aws_error :: {:error, map}
  @type request_error :: {:error, String.t}

  @spec request(ExAws.Operation.Query.t, list | nil) :: aws_success | aws_error | request_error
  def request(operation, opts \\ []) do
    @ex_aws.request(operation, opts)
  end
end
