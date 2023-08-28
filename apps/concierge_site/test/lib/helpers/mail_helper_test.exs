defmodule ConcerigeSite.Helpers.MailHelperTest do
  @moduledoc false
  use ConciergeSite.DataCase, async: true
  alias ConciergeSite.Helpers.MailHelper

  describe "Logo function" do
    test "mbta_logo/0 returns URL of MBTA Logo" do
      assert MailHelper.mbta_logo() =~ "/images/icons/t-logo@2x.png"
    end
  end

  describe "manage_subscription_url" do
    test "generates url with token" do
      url = MailHelper.manage_subscriptions_url()
      assert url =~ "http"
      assert url =~ ~r/trips$/
    end
  end

  describe "track_open_url" do
    test "generates url with notification and alert ids" do
      url =
        MailHelper.track_open_url(%AlertProcessor.Model.Notification{
          alert_id: "foo",
          id: "bar"
        })

      assert url =~ "http"
      assert url =~ "/email_opened/notification/foo/bar/img.gif"
    end
  end
end
