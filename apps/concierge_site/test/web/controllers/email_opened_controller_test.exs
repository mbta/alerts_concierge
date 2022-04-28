defmodule ConciergeSite.EmailOpenedControllerTest do
  @moduledoc false
  use ConciergeSite.ConnCase, async: true

  describe "/notification_email_opened" do
    test "returns empty image/gif successfully", %{conn: conn} do
      resp =
        get(conn, "/notification_email_opened", %{
          "notification_id" => "test",
          "alert_id" => "test"
        })

      assert %{status: 200, resp_body: ""} = resp
      assert ["image/gif"] = get_resp_header(resp, "content-type")
    end
  end
end
