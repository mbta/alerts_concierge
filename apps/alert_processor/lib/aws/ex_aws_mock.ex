defmodule ExAws.Mock do
  @moduledoc """
  Module to act as mock for AWS api.
  Mock modeled after ex_aws implementation.
  https://github.com/CargoSense/ex_aws/blob/master/lib/ex_aws/sns/parsers.ex#L62
  """

  @doc """
  request/1 takes the operation to be sent via the aws api and returns a tuple.
  """
  @spec request(ExAws.Operation.t(), []) :: {:ok, term} | {:error, term}
  def request(operation, []) do
    # Take a realistic amount of time to "respond" to the request. This is short enough to not
    # have any measurable impact on test runtime, but means load tests performing thousands of
    # requests will have similar results as they would in production. The value is based on the
    # average response time of a real SNS `publish` request during a system-wide alert.
    :timer.sleep(40)

    send(self(), operation.action)

    case operation.action do
      :publish ->
        {:ok,
         %{
           body: %{
             message_id: "123",
             request_id: "345"
           }
         }}

      :list_phone_numbers_opted_out ->
        case operation.params["nextToken"] do
          nil ->
            {:ok,
             %{
               body: %{
                 phone_numbers: ["+19999999999"],
                 next_token: "this_is_a_token",
                 request_id: "123"
               }
             }}

          "error" ->
            {:error,
             {:http_error, 400,
              %{
                code: "Throttling",
                detail: "",
                message: "Rate exceeded",
                request_id: "531e7c21-0317-5eba-a114-2efd4caef900",
                type: "Sender"
              }}}

          _ ->
            {:ok,
             %{
               body: %{
                 phone_numbers: ["+15555555555"],
                 next_token: "",
                 request_id: "456"
               }
             }}
        end

      :opt_in_phone_number ->
        {:ok,
         %{
           body: %{
             request_id: "345"
           }
         }}

      _ ->
        {:error, operation}
    end
  end
end
