defmodule MbtaServer.AlertProcessor.AlertParser do
  @moduledoc """
  Module used to parse alerts from api and transform into Alert structs and pass along
  relevant information to subscription filter engine.
  """
  alias MbtaServer.AlertProcessor.{JsonApiClient, SubscriptionFilterEngine}

  @doc """
  process_alerts/0 entry point for fetching json data from api and, transforming, storing and passing to
  subscription engine to process before sending.
  """
  @spec process_alerts() :: :ok | :error
  def process_alerts() do
    case JsonApiClient.get_alerts do
      {:error, message} ->
        message
      alert_data ->
        alert_data
        |> Enum.flat_map(&parse_alert/1)
        |> Enum.map(&SubscriptionFilterEngine.process_alert/1)
    end
  end

  @doc """
  parse_alert/1 takes a map of alert information and extracts relevant fields.
  """
  @spec parse_alert(Map) :: [%{header: String.t}]
  defp parse_alert(%{"attributes" => %{"header" => header}}) when is_binary(header) do
    [%{header: header}]
  end

  defp parse_alert(_) do
    []
  end
end
