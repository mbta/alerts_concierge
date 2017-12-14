defmodule ConciergeSite.FeedbackTest do
  use ConciergeSite.FeatureCase, async: true

  import Wallaby.Query, only: [xpath: 1]

  test "leaving feedback", %{session: session} do
    session
    |> visit("/")
    |> assert_has(xpath("//a[text()='Send us your comments or questions' and @href='http://mbtafeedback.com/']"))
  end
end
