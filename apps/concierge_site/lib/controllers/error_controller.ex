defmodule ConciergeSite.ErrorController do
  @moduledoc """
  Simple controller to attempt to debug why certain errors are not being logged
  and/or pushed to Splunk when in production.
  """

  use ConciergeSite.Web, :controller

  def five_hundred(conn, _params) do
    send_resp(conn, 500, "")
  end

  def raise(_conn, _params) do
    raise "Boom!"
  end
end
