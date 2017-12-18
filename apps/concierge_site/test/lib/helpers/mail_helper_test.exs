defmodule ConcerigeSite.Helpers.MailHelperTest do
  @moduledoc false
  use ConciergeSite.DataCase
  import AlertProcessor.Factory
  alias ConciergeSite.Helpers.MailHelper
  alias AlertProcessor.{Model.Alert, Model.InformedEntity}

  @alert %Alert{
    id: "1",
    header: "This is a Test",
    service_effect: "Service Effect"
  }

  describe "Logo function" do
    test "mbta_logo/0 returns URL of MBTA Logo" do
      assert MailHelper.mbta_logo() =~ "/images/icons/t-logo@2x.png"
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
      facility_alert = Map.merge(@alert, %{informed_entities: [%InformedEntity{route_type: nil, facility_type: :elevator}]})
      unparsed_facility_alert = Map.merge(@alert, %{informed_entities: [%InformedEntity{route_type: nil, facility_type: nil}]})

      red = "/images/icons/icn_red-line.png"
      blue = "/images/icons/icn_blue-line.png"
      orange = "/images/icons/icn_orange-line.png"
      green = "/images/icons/icn_green-line.png"
      facility = "/images/icons/icn_facility.png"

      assert MailHelper.logo_for_alert(red_alert) =~ red
      assert MailHelper.logo_for_alert(blue_alert) =~ blue
      assert MailHelper.logo_for_alert(orange_alert) =~ orange
      assert MailHelper.logo_for_alert(mattapan_alert) =~ red
      assert MailHelper.logo_for_alert(green_b_alert) =~ green
      assert MailHelper.logo_for_alert(green_c_alert) =~ green
      assert MailHelper.logo_for_alert(green_d_alert) =~ green
      assert MailHelper.logo_for_alert(green_e_alert) =~ green
      assert MailHelper.logo_for_alert(facility_alert) =~ facility
      assert MailHelper.logo_for_alert(unparsed_facility_alert) =~ facility
    end

    test "logo_for_alert/1 returns commuter rail" do
      alert = Map.merge(@alert, %{informed_entities: [%InformedEntity{route_type: 2}]})
      commuter_rail = "images/icons/icn_commuter.png"

      assert MailHelper.logo_for_alert(alert) =~ commuter_rail
    end

    test "logo_for_alert/1 return bus" do
      alert = Map.merge(@alert, %{informed_entities: [%InformedEntity{route_type: 3}]})
      bus = "images/icons/icn_bus.png"

      assert MailHelper.logo_for_alert(alert) =~ bus
    end

    test "logo_for_alert/1 return ferry" do
      alert = Map.merge(@alert, %{informed_entities: [%InformedEntity{route_type: 4}]})
      ferry = "images/icons/icn_ferry.png"

      assert MailHelper.logo_for_alert(alert) =~ ferry
    end

    test "logo_for_alert/1 return facility" do
      alert = Map.merge(@alert, %{informed_entities: [%InformedEntity{facility_type: :elevator}]})
      facility = "images/icons/icn_facility.png"

      assert MailHelper.logo_for_alert(alert) =~ facility
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
      facility_alert = Map.merge(@alert, %{informed_entities: [%InformedEntity{route_type: nil, facility_type: :elevator}]})
      unparsed_facility_alert = Map.merge(@alert, %{informed_entities: [%InformedEntity{route_type: nil, facility_type: nil}]})

      red = "logo-red-line"
      blue = "logo-blue-line"
      orange = "logo-orange-line"
      green = "logo-green-line"
      facility = "logo-facility"

      assert MailHelper.alt_text_for_alert(red_alert) == red
      assert MailHelper.alt_text_for_alert(blue_alert) == blue
      assert MailHelper.alt_text_for_alert(orange_alert) == orange
      assert MailHelper.alt_text_for_alert(mattapan_alert) == red
      assert MailHelper.alt_text_for_alert(green_b_alert) == green
      assert MailHelper.alt_text_for_alert(green_c_alert) == green
      assert MailHelper.alt_text_for_alert(green_d_alert) == green
      assert MailHelper.alt_text_for_alert(green_e_alert) == green
      assert MailHelper.alt_text_for_alert(facility_alert) == facility
      assert MailHelper.alt_text_for_alert(unparsed_facility_alert) == facility
    end

    test "alt_text_for_alert/1 returns commuter rail" do
      alert = Map.merge(@alert, %{informed_entities: [%InformedEntity{route_type: 2}]})
      commuter_rail = "logo-commuter-rail"

      assert MailHelper.alt_text_for_alert(alert) == commuter_rail
    end

    test "alt_text_for_alert/1 return bus" do
      alert = Map.merge(@alert, %{informed_entities: [%InformedEntity{route_type: 3}]})
      bus = "logo-bus"

      assert MailHelper.alt_text_for_alert(alert) == bus
    end

    test "alt_text_for_alert/1 return ferry" do
      alert = Map.merge(@alert, %{informed_entities: [%InformedEntity{route_type: 4}]})
      ferry = "logo-ferry"

      assert MailHelper.alt_text_for_alert(alert) == ferry
    end

     test "alt_text_for_alert/1 return facility" do
      alert = Map.merge(@alert, %{informed_entities: [%InformedEntity{facility_type: :escalator}]})
      facility = "logo-facility"

      assert MailHelper.alt_text_for_alert(alert) == facility
    end
  end

  describe "unsubscribe_url" do
    test "generates url with token" do
      user = insert(:user)
      url = MailHelper.unsubscribe_url(user)
      assert url =~ "http"
      assert url =~ ~r/unsubscribe\/(.+)/
    end
  end

  describe "disable_account_url" do
    test "generates url with token" do
      user = insert(:user)
      url = MailHelper.disable_account_url(user)
      assert url =~ "http"
      assert url =~ ~r/my-account\/confirm_disable\?token=(.+)/
    end
  end

  describe "reset_password_url" do
    test "generates url with password reset id" do
      password_reset_id = "this-is-a-password-reset-id"
      url = MailHelper.reset_password_url(password_reset_id)
      assert url =~ "http"
      assert url =~ "reset-password/#{password_reset_id}/edit"
    end
  end

  describe "manage_subscription_url" do
    test "generates url with token" do
      user = insert(:user)
      url = MailHelper.manage_subscriptions_url(user)
      assert url =~ "http"
      assert url =~ ~r/my-subscriptions\?token=(.+)/
    end
  end

  describe "feedback_url" do
    test "fetches url from environment" do
      assert MailHelper.feedback_url() == "http://mbtafeedback.com/"
    end
  end
end
