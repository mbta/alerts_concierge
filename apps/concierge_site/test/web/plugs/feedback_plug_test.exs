defmodule ConciergeSite.FeedbackPlugTest do
  @moduledoc false
  use ConciergeSite.ConnCase, async: true
  alias ConciergeSite.Plugs.FeedbackPlug

  test "init/1 returns what it's given" do
    assert FeedbackPlug.init("test") == "test"
  end

  test "adds feedback url to assigns" do
    conn =
      build_conn()
      |> FeedbackPlug.call(%{})

    assert conn.assigns.feedback_url == "http://mbtafeedback.com/"
  end
end
