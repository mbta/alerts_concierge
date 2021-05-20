defmodule ConciergeSite.RejectedEmailControllerTest do
  @moduledoc false
  use ConciergeSite.ConnCase, async: true

  alias AlertProcessor.{Model.User, Repo}
  import ExUnit.CaptureLog

  describe "handle_message/2" do
    defp post_raw_message(conn, data) do
      conn
      |> put_req_header("content-type", "text/plain")
      |> post(rejected_email_path(conn, :handle_message), data)
    end

    defp post_message(conn, message), do: post_raw_message(conn, Poison.encode!(message))

    defp post_notification(conn, notification) do
      post_message(conn, %{"Type" => "Notification", "Message" => Poison.encode!(notification)})
    end

    test "handles subscribe confirmations", %{conn: conn} do
      bypass = Bypass.open()
      Bypass.expect_once(bypass, "GET", "/test_url", fn conn -> Plug.Conn.resp(conn, 200, "") end)
      url = "http://localhost:#{bypass.port}/test_url"

      conn = post_message(conn, %{"Type" => "SubscriptionConfirmation", "SubscribeURL" => url})

      assert response(conn, :no_content)
    end

    test "handles unsubscribe confirmations", %{conn: conn} do
      conn = post_message(conn, %{"Type" => "UnsubscribeConfirmation"})

      assert response(conn, :no_content)
    end

    test "handles bounce notifications", %{conn: conn} do
      %{id: user_id, email: email} = insert(:user, communication_mode: "email")

      conn =
        post_notification(conn, %{
          "notificationType" => "Bounce",
          "bounce" => %{
            "bounceType" => "Permanent",
            "bouncedRecipients" => [%{"emailAddress" => email}]
          }
        })

      assert response(conn, :no_content)
      user = Repo.get!(User, user_id)
      assert %{communication_mode: "none", email_rejection_status: "bounce"} = user
    end

    test "only disables email on a permanent bounce", %{conn: conn} do
      %{id: user_id, email: email} = insert(:user, communication_mode: "email")

      conn =
        post_notification(conn, %{
          "notificationType" => "Bounce",
          "bounce" => %{
            "bounceType" => "Transient",
            "bouncedRecipients" => [%{"emailAddress" => email}]
          }
        })

      assert response(conn, :no_content)
      user = Repo.get!(User, user_id)
      assert %{communication_mode: "email", email_rejection_status: nil} = user
    end

    test "handles complaint notifications", %{conn: conn} do
      %{id: user_id, email: email} = insert(:user, communication_mode: "email")

      conn =
        post_notification(conn, %{
          "notificationType" => "Complaint",
          "complaint" => %{"complainedRecipients" => [%{"emailAddress" => email}]}
        })

      assert response(conn, :no_content)
      user = Repo.get!(User, user_id)
      assert %{communication_mode: "none", email_rejection_status: "complaint"} = user
    end

    test "handles not-spam notifications", %{conn: conn} do
      %{id: user_id, email: email} =
        insert(:user, communication_mode: "none", email_rejection_status: "complaint")

      conn =
        post_notification(conn, %{
          "notificationType" => "Complaint",
          "complaint" => %{
            "complaintFeedbackType" => "not-spam",
            "complainedRecipients" => [%{"emailAddress" => email}]
          }
        })

      assert response(conn, :no_content)
      user = Repo.get!(User, user_id)
      assert %{communication_mode: "email", email_rejection_status: nil} = user
    end

    test "logs a warning if no matching user is found", %{conn: conn} do
      logs =
        capture_log(fn ->
          conn =
            post_notification(conn, %{
              "notificationType" => "Complaint",
              "complaint" => %{"complainedRecipients" => [%{"emailAddress" => "a@example.com"}]}
            })

          assert response(conn, :no_content)
        end)

      assert logs =~ "event=user_not_found email=a@example.com"
    end

    @tag :capture_log
    test "handles invalid JSON", %{conn: conn} do
      conn = post_raw_message(conn, "{this isn't valid!}")

      assert response(conn, :bad_request)
    end

    @tag :capture_log
    test "handles an over-large request body", %{conn: conn} do
      conn = post_raw_message(conn, String.duplicate("a", 8_000_001))

      assert response(conn, :request_entity_too_large)
    end

    @tag :capture_log
    test "handles an invalid message signature", %{conn: conn} do
      conn = post_message(conn, %{"Signature" => "error"})

      assert response(conn, :unauthorized)
    end
  end
end
