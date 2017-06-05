defmodule AlertProcessor.DigestMailHelperTest do
  @moduledoc false
  use ExUnit.Case
  alias AlertProcessor.{DigestMailHelper, Model.Alert, Model.InformedEntity}

  @alert %Alert{
    id: "1",
    header: "This is a Test",
    service_effect: "Service Effect"
  }

  describe "Logo function" do
    test "mbta_logo/0 returns URL of MBTA Logo" do
      assert DigestMailHelper.mbta_logo() == "https://example.com/assets/icons/icn_accessibility@2x.png"
    end
  end

  describe "Route type icon functions" do
    test "logo_for_alert/1 for subway returns correct line icon" do
      red_alert = Map.merge(@alert, %{informed_entities: [%InformedEntity{route_type: 0, route: "Red"}]})
      blue_alert = Map.merge(@alert, %{informed_entities: [%InformedEntity{route_type: 1, route: "Blue"}]})
      orange_alert = Map.merge(@alert, %{informed_entities: [%InformedEntity{route_type: 0, route: "Orange"}]})
      mattapan_alert = Map.merge(@alert, %{informed_entities: [%InformedEntity{route_type: 0, route: "Mattapan"}]})
      green_b_alert = Map.merge(@alert, %{informed_entities: [%InformedEntity{route_type: 0, route: "Green-B"}]})
      green_c_alert = Map.merge(@alert, %{informed_entities: [%InformedEntity{route_type: 0, route: "Green-C"}]})
      green_d_alert = Map.merge(@alert, %{informed_entities: [%InformedEntity{route_type: 0, route: "Green-D"}]})
      green_e_alert = Map.merge(@alert, %{informed_entities: [%InformedEntity{route_type: 0, route: "Green-E"}]})

      red = "https://example.com/assets/icons/icn_red-line.png"
      blue = "https://example.com/assets/icons/icn_blue-line.png"
      orange = "https://example.com/assets/icons/icn_orange-line.png"
      green = "https://example.com/assets/icons/icn_green-line.png"

      assert DigestMailHelper.logo_for_alert(red_alert) == red
      assert DigestMailHelper.logo_for_alert(blue_alert) == blue
      assert DigestMailHelper.logo_for_alert(orange_alert) == orange
      assert DigestMailHelper.logo_for_alert(mattapan_alert) == red
      assert DigestMailHelper.logo_for_alert(green_b_alert) == green
      assert DigestMailHelper.logo_for_alert(green_c_alert) == green
      assert DigestMailHelper.logo_for_alert(green_d_alert) == green
      assert DigestMailHelper.logo_for_alert(green_e_alert) == green
    end

    test "logo_for_alert/1 returns commuter rail" do
      alert = Map.merge(@alert, %{informed_entities: [%InformedEntity{route_type: 2}]})
      commuter_rail = "https://example.com/assets/icons/commuter-rail.png"

      assert DigestMailHelper.logo_for_alert(alert) == commuter_rail
    end

    test "logo_for_alert/1 return bus" do
      alert = Map.merge(@alert, %{informed_entities: [%InformedEntity{route_type: 3}]})
      bus = "https://example.com/assets/icons/bus.png"

      assert DigestMailHelper.logo_for_alert(alert) == bus
    end

    test "logo_for_alert/1 return ferry" do
      alert = Map.merge(@alert, %{informed_entities: [%InformedEntity{route_type: 4}]})
      ferry = "https://example.com/assets/icons/ferry.png"

      assert DigestMailHelper.logo_for_alert(alert) == ferry
    end
  end

  describe "Alt text functions" do
   test "alt_text_for_alert/1 for subway returns correct line icon" do
      red_alert = Map.merge(@alert, %{informed_entities: [%InformedEntity{route_type: 0, route: "Red"}]})
      blue_alert = Map.merge(@alert, %{informed_entities: [%InformedEntity{route_type: 1, route: "Blue"}]})
      orange_alert = Map.merge(@alert, %{informed_entities: [%InformedEntity{route_type: 0, route: "Orange"}]})
      mattapan_alert = Map.merge(@alert, %{informed_entities: [%InformedEntity{route_type: 0, route: "Mattapan"}]})
      green_b_alert = Map.merge(@alert, %{informed_entities: [%InformedEntity{route_type: 0, route: "Green-B"}]})
      green_c_alert = Map.merge(@alert, %{informed_entities: [%InformedEntity{route_type: 0, route: "Green-C"}]})
      green_d_alert = Map.merge(@alert, %{informed_entities: [%InformedEntity{route_type: 0, route: "Green-D"}]})
      green_e_alert = Map.merge(@alert, %{informed_entities: [%InformedEntity{route_type: 0, route: "Green-E"}]})

      red = "logo-red-line"
      blue = "logo-blue-line"
      orange = "logo-orange-line"
      green = "logo-green-line"

      assert DigestMailHelper.alt_text_for_alert(red_alert) == red
      assert DigestMailHelper.alt_text_for_alert(blue_alert) == blue
      assert DigestMailHelper.alt_text_for_alert(orange_alert) == orange
      assert DigestMailHelper.alt_text_for_alert(mattapan_alert) == red
      assert DigestMailHelper.alt_text_for_alert(green_b_alert) == green
      assert DigestMailHelper.alt_text_for_alert(green_c_alert) == green
      assert DigestMailHelper.alt_text_for_alert(green_d_alert) == green
      assert DigestMailHelper.alt_text_for_alert(green_e_alert) == green
    end

    test "alt_text_for_alert/1 returns commuter rail" do
      alert = Map.merge(@alert, %{informed_entities: [%InformedEntity{route_type: 2}]})
      commuter_rail = "logo-commuter-rail"

      assert DigestMailHelper.alt_text_for_alert(alert) == commuter_rail
    end

    test "alt_text_for_alert/1 return bus" do
      alert = Map.merge(@alert, %{informed_entities: [%InformedEntity{route_type: 3}]})
      bus = "logo-bus"

      assert DigestMailHelper.alt_text_for_alert(alert) == bus
    end

    test "alt_text_for_alert/1 return ferry" do
      alert = Map.merge(@alert, %{informed_entities: [%InformedEntity{route_type: 4}]})
      ferry = "logo-ferry"

      assert DigestMailHelper.alt_text_for_alert(alert) == ferry
    end
  end
end
