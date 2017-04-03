defmodule MbtaServer.AlertProcessor.ApiClient do
  @moduledoc """
  HTTPoison wrapper for MBTA API
  """
  use HTTPoison.Base

  defp process_url(url) do
    "https://api.mbtace.com/" <> url
  end

  defp process_response_body(body) do
    body
    |> Poison.decode!
  end
end
