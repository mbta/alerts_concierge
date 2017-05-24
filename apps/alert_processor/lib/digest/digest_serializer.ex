defmodule AlertProcessor.DigestSerializer do
  @moduledoc """
  Converts alerts into digest email text
  """
  alias AlertProcessor.Model.{Alert, Digest}

  @doc """
  Takes a Digest and serializes each alert into
  the format it will be presented in an email
  """
  @spec serialize([Digest.t]) :: iodata
  def serialize(digest) do
    digest.alerts
    |> Enum.map(&serialize_alert/1)
    |> Enum.join(" ")
  end

  @spec serialize_alert(Alert.t) :: String.t
  defp serialize_alert(alert) do
    # TODO:  Waiting on spec
    alert.header
  end
end
