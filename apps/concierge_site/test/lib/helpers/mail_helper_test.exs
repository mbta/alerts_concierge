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

  describe "feedback_url" do
    test "fetches url from environment" do
      assert MailHelper.feedback_url() == "http://mbtafeedback.com/"
    end
  end

  describe "reset_password_url" do
    test "generates url with password reset id" do
      reset_token = "some-reset-token"
      url = MailHelper.reset_password_url(reset_token)
      assert url =~ "http"
      assert url =~ "password_resets/#{reset_token}/edit"
    end
  end
end
