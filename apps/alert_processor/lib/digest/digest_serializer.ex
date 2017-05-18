defmodule AlertProcessor.DigestSerializer do
  @moduledoc """
  Converts alerts into digest email text
  """
  alias AlertProcessor.Model.{Alert, Digest, User}

  @doc """
  Takes a Digest and serializes each alert into
  the format it will be presented in an email
  """
  @spec serialize([Digest.t]) :: [{User.t, [String.t]}]
  def serialize(digests) do
    digests
    |> Enum.map(fn(digest) ->
      serialized_alerts = Enum.map(digest.alerts, fn(alert) ->
        serialize_alert(alert)
      end)
      Map.put(digest, :serialized_alerts, serialized_alerts)
    end)
  end

  @spec serialize_alert(Alert.t) :: String.t
  defp serialize_alert(alert) do
    # TODO: Waiting on spec
    alert.header
  end
end
