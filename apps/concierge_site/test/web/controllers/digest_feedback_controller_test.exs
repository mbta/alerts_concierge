defmodule ConciergeSite.DigestFeedbackControllerTest do
  @moduledoc false
  use ConciergeSite.ConnCase, async: true

  describe "feedback/2" do
    test "helpful=yes", %{conn: conn} do
      conn =
        get(
          conn,
          digest_feedback_path(conn, :feedback, %{
            "rating" => "yes"
          })
        )

      assert html_response(conn, 200) =~ "Thanks for your feedback"
    end

    test "helpful=no", %{conn: conn} do
      conn =
        get(
          conn,
          digest_feedback_path(conn, :feedback, %{
            "rating" => "no"
          })
        )

      assert html_response(conn, 200) =~ "Feedback form"
    end

    test "bad input", %{conn: conn} do
      conn =
        get(
          conn,
          digest_feedback_path(conn, :feedback)
        )

      assert html_response(conn, 200) =~ "An error occurred"
    end
  end

  describe "new/2" do
    test "success", %{conn: conn} do
      conn =
        post(conn, digest_feedback_path(conn, :new), %{
          "why" => "reason why",
          "what" => "reason what"
        })

      assert json_response(conn, 200) == %{"status" => "ok"}
    end

    test "fail validation", %{conn: conn} do
      conn = post(conn, digest_feedback_path(conn, :new), %{})

      assert json_response(conn, 200) == %{"status" => "error", "error" => "invalid input"}
    end
  end
end
