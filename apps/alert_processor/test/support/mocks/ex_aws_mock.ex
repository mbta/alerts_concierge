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
    send self(), operation.action
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
            phone_numbers: ["9999999999"],
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
