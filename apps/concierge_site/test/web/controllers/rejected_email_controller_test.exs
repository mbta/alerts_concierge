defmodule ConciergeSite.RejectedEmailControllerTest do
  @moduledoc false
  use ConciergeSite.ConnCase, async: true

  @bounce %{
    "notificationType" => "Bounce",
    "bounce" => %{
      "bouncedRecipients" => [
        %{
          "emailAddress" => "bob@example.com"
        }
      ]
    }
  }

  @complaint %{
    "notificationType" => "Complaint",
    "complaint" => %{
      "complainedRecipients" => [
        %{
          "emailAddress" => "jane@example.com"
        }
      ]
    }
  }

  describe "bounced emails" do
    test "POST /rejected_email succeeds", %{conn: conn} do
      insert(:user, email: "bob@example.com")

      conn = post(conn, rejected_email_path(conn, :handle_rejected_email), @bounce)

      assert json_response(conn, 200)
    end

    test "POST /rejected_email with no user", %{conn: conn} do
      conn = post(conn, rejected_email_path(conn, :handle_rejected_email), @bounce)
      assert json_response(conn, 200)
    end
  end

  describe "complaint emails" do
    test "POST /rejected_email succeeds", %{conn: conn} do
      insert(:user, email: "jane@example.com")

      conn = post(conn, rejected_email_path(conn, :handle_rejected_email), @complaint)

      assert json_response(conn, 200)
    end
  end
end
