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
    {:ok, operation}
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
  @spec publish(String.t, Map) :: {:ok, Map}
  def publish(message, opts) do
    send self(), :published_sms
    request(message, opts)
  end

  @spec request(String.t, Map) :: {:ok, Map}
  defp request(message, params) do
    {:ok,
      %{
        path: "/",
        params: %{
          "Action" => "Publish",
          "Message" => message,
          "PhoneNumber" => params[:phone_number]
        },
        service: :sns,
        action: :publish,
        parser: &ExAws.SNS.Parsers.parse/2
      }
    }
  end
end
