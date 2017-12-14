defmodule ConciergeSite.Plugs.FeedbackPlug do
  @moduledoc """
  Plug to get the feedback link from the config and put it in conn so that it's
  available later in the pipeline
  """

  import Plug.Conn
  alias AlertProcessor.Helpers.ConfigHelper

  @behaviour Plug

  def init(opts), do: opts

  def call(conn, _) do
    assign(conn, :feedback_url, feedback_url())
  end

  defp feedback_url do
    case ConfigHelper.get_string(:feedback_url, :concierge_site) do
      "" -> nil
      nil -> nil
      url -> url
    end
  end
end
