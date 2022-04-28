defmodule ConciergeSite.EmailOpenedController do
  use ConciergeSite.Web, :controller
  require Logger

  def notification(conn, %{"alert_id" => alert_id, "notification_id" => notification_id}) do
    Logger.info("email_opened alert_id=#{alert_id} notification_id=#{notification_id}")
    conn = put_resp_content_type(conn, "image/gif", nil)
    send_resp(conn, 200, "")
  end
end
