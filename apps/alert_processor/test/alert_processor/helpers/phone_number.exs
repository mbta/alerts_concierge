defmodule AlertProcessor.Helpers.PhoneNumberTest do
  use ExUnit.Case, async: true

  alias AlertProcessor.Helpers.PhoneNumber

  describe "strip_us_country_code/1" do
    test "strips the US country code from the beginning of a phone number if present" do
      assert PhoneNumber.strip_us_country_code("+15555555555") == "5555555555"
    end

    test "doesn't alter a phone number without a US country code" do
      assert PhoneNumber.strip_us_country_code("5555555555") == "5555555555"
    end

    test "ignores nil values" do
      assert PhoneNumber.strip_us_country_code(nil) == nil
    end
  end
end
