defmodule ExAws.Mock do
  @moduledoc "Mock module to stand in for `ExAws` in tests."

  defmodule SNS do
    @moduledoc false
    @spec verify_message(%{String.t() => String.t()}) :: :ok | {:error, String.t()}
    def verify_message(%{"Signature" => "error"}), do: {:error, "invalid signature"}
    def verify_message(_), do: :ok
  end

  @spec request(ExAws.Operation.t(), Keyword.t()) :: {:ok, term} | {:error, term}
  def request(operation, _) do
    # Take a realistic amount of time to "respond" to the request. This is short enough to not
    # have any measurable impact on test runtime, but means load tests performing thousands of
    # requests will have similar results as they would in production. The value is based on the
    # average response time of a real SNS `publish` request during a system-wide alert.
    :timer.sleep(40)

    send(self(), {operation.action, operation.params})

    case operation.action do
      :publish ->
        {:ok,
         %{
           body: %{
             message_id: "123",
             request_id: "345"
           }
         }}

      :check_if_phone_number_is_opted_out ->
        case operation.params["phoneNumber"] do
          "+18675309" -> {:ok, %{body: %{is_opted_out: true}}}
          "+1816613" -> {:error, :mock}
          _ -> {:ok, %{body: %{is_opted_out: false}}}
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
