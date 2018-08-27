defmodule ConciergeSite.RejectedEmailControllerTest do
  use ConciergeSite.ConnCase, async: true
  alias AlertProcessor.{Model.User, Repo}

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
    test "POST /rejected_email sets users on vacation mode", %{conn: conn} do
      insert(:user, email: "bob@example.com", vacation_start: nil, vacation_end: nil)

      conn = post(conn, rejected_email_path(conn, :handle_rejected_email), @bounce)

      [user] = Repo.all(User)

      assert json_response(conn, 200)
      refute user.vacation_start == nil
      refute user.vacation_end == nil
    end

    test "POST /rejected_email with no user", %{conn: conn} do
      conn = post(conn, rejected_email_path(conn, :handle_rejected_email), @bounce)
      assert json_response(conn, 200)
    end
  end

  describe "complaint emails" do
    test "POST /rejected_email sets users on vacation mode", %{conn: conn} do
      insert(:user, email: "jane@example.com", vacation_start: nil, vacation_end: nil)

      conn = post(conn, rejected_email_path(conn, :handle_rejected_email), @complaint)

      [user] = Repo.all(User)

      assert json_response(conn, 200)
      refute user.vacation_start == nil
      refute user.vacation_end == nil
    end
  end
end
