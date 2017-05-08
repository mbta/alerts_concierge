defmodule ExAws.Mock do
  @moduledoc """
  Module to act as mock for AWS api.
  Mock modeled after ex_aws implementation.
  https://github.com/CargoSense/ex_aws/blob/master/lib/ex_aws/sns/parsers.ex#L62
  """

  @doc """
  request/1 takes the operation to be sent via the aws api and returns a tuple.
  """
  @spec request(Map, List) :: {:ok, Map}
  def request(operation, []) do
    case operation.action do
      :publish ->
        {:ok, %{
          body: %{
            message_id: "123",
            request_id: "345"
          }
        }}
      :list_phone_numbers_opted_out ->
        {:ok, %{
          body: %{
            phone_numbers: ["+19999999999"],
            next_token: nil,
            request_id: "123"
          }
        }}
      :opt_in_phone_number ->
        {:ok, %{
          body: %{
            request_id: "345"
          }
        }}
      _ ->
        {:error, operation}
    end
  end
end

defmodule ExAws.SNS.Mock do
  @moduledoc """
  Module to act as mock for AWS SNS api.
  Mock modeled after ex_aws implementation.
  https://github.com/CargoSense/ex_aws/blob/master/lib/ex_aws/sns.ex#L361
  """

  @doc """
  publish/2 takes the message to be sent and map of properties to pass with the message.
  also sends message to self to make function call tracking easier within tests.
  """
  @spec publish(String.t, Map) :: {:ok, ExAws.Operation.Query.t}
  def publish(message, opts) do
    send self(), :published_sms
    ExAws.SNS.publish(message, opts)
  end

  @spec list_phone_numbers_opted_out() :: {:ok, ExAws.Operation.Query.t}
  def list_phone_numbers_opted_out() do
    send self(), :list_phone_numbers_opted_out
    ExAws.SNS.list_phone_numbers_opted_out()
  end

  @spec list_phone_numbers_opted_out(String.t) :: {:ok, ExAws.Operation.Query.t}
  def list_phone_numbers_opted_out(next_token) do
    send self(), :list_phone_numbers_opted_out
    ExAws.SNS.list_phone_numbers_opted_out(next_token)
  end

  @spec opt_in_phone_number(String.t) :: {:ok, ExAws.Operation.Query.t}
  def opt_in_phone_number(phone_number) do
    send self(), :opt_in_phone_number
    ExAws.SNS.opt_in_phone_number(phone_number)
  end
end
