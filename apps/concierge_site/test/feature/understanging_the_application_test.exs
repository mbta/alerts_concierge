defmodule ConciergeSite.UnderstandingTheApplicationTest do
  use ConciergeSite.FeatureCase, async: true

  import Wallaby.Query, only: [xpath: 1]

  test "viewing more information about the beta", %{session: session} do
    session
    |> visit("/")
    |> assert_has(xpath("//a[contains(text(), 'Learn more about T-Alerts') and @href='https://www.mbta.com/about-t-alerts-beta']"))
  end

  test "leaving feedback if something is not easy to understand", %{session: session} do
    session
    |> visit("/")
    |> assert_has(xpath("//a[text()='Send us your comments or questions' and @href='http://mbtafeedback.com/']"))
  end
end
