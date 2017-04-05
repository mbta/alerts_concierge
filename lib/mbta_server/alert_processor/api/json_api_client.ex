defmodule MbtaServer.AlertProcessor.JsonApiClient do
  @moduledoc """
  Client for formatting JSONAPI requests
  """
  @client MbtaServer.AlertProcessor.ApiClient

  @doc """
  Helper function that fetches all alerts from
  MBTA Alerts API
  """
  @spec get_alerts() :: Map | {atom, Map}
  def get_alerts do
   case get("/alerts") do
      {:ok, %{body: %{"data" => data}}} -> data
      {:error, message} -> {:error, message}
    end
  end

  @doc """
  Function that takes URL path and Map of params and
  generates JSONAPI compliant URL for MBTA Alerts API
  """
  @spec get(String.t, Map | %{}) :: {:ok, HTTPoison.AsyncResponse.t}
                            | {:ok, HTTPoison.Response.t}
                            | {:error, HTTPoison.Error.t}
  def get(path, params \\ %{}) when is_binary(path) do
    path
    |> url
    |> add_params_to_url(params)
    |> @client.get()
  end

  @spec url(String.t) :: String.t
  defp url(path), do: path

  @spec add_params_to_url(String.t, Map) :: String.t
  defp add_params_to_url(url, params) do
   params
   |> stringify_params
   |> append_params(url)
  end

  @spec stringify_params(Map) :: [String.t]
  defp stringify_params(params) do
    params
    |> Enum.map(fn({k, v}) ->
      case v do
        [_h | _t] ->
          k <> "=" <> Enum.join(v, ",")
        _ ->
          ""
      end
    end)
  end

  @spec append_params([String.t], String.t) :: String.t
  defp append_params(params, url) do
    url <> "?" <> Enum.join(params, "&")
  end
end
