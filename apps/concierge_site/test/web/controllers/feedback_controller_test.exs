defmodule ConciergeSite.FeedbackControllerTest do
  use ConciergeSite.ConnCase, async: true
  import AlertProcessor.Factory

  describe "feedback/2" do
    test "helpful=yes, alert not in db", %{conn: conn} do
      conn =
        get(
          conn,
          feedback_path(conn, :feedback, %{
            "alert_id" => "123",
            "rating" => "yes",
            "user_id" => "416fa5a8-d3bf-4af7-a8ae-29415b70eff0"
          })
        )

      assert html_response(conn, 200) =~ "Thanks for your feedback"
    end

    test "helpful=yes, alert found", %{conn: conn} do
      alert = insert(:saved_alert)

      conn =
        get(
          conn,
          feedback_path(conn, :feedback, %{
            "alert_id" => alert.alert_id,
            "rating" => "yes",
            "user_id" => "416fa5a8-d3bf-4af7-a8ae-29415b70eff0"
          })
        )

      assert html_response(conn, 200) =~ "Thanks for your feedback"
    end

    test "helpful=no", %{conn: conn} do
      conn =
        get(
          conn,
          feedback_path(conn, :feedback, %{
            "alert_id" => "123",
            "rating" => "no",
            "user_id" => "416fa5a8-d3bf-4af7-a8ae-29415b70eff0"
          })
        )

      assert html_response(conn, 200) =~ "Alert feedback form"
    end

    test "bad input", %{conn: conn} do
      conn =
        get(
          conn,
          feedback_path(conn, :feedback)
        )

      assert html_response(conn, 200) =~ "An error occurred"
    end
  end

  describe "new/2" do
    test "success", %{conn: conn} do
      alert = insert(:saved_alert)

      conn =
        post(conn, feedback_path(conn, :new), %{
          "alert_id" => alert.alert_id,
          "user_id" => "416fa5a8-d3bf-4af7-a8ae-29415b70eff0",
          "why" => "reason why",
          "what" => "reason what"
        })

      assert json_response(conn, 200) == %{"status" => "ok"}
    end

    test "fail validation", %{conn: conn} do
      conn = post(conn, feedback_path(conn, :new), %{})

      assert json_response(conn, 200) == %{"status" => "error", "error" => "invalid input"}
    end
  end
end
