defmodule ConciergeSite.PasswordHelperTest do
  use ExUnit.Case, async: true
  alias ConciergeSite.PasswordHelper

  describe "password_regex_string" do
    test "returns a regex string that matches valid passwords" do
      regex = ~r/#{PasswordHelper.password_regex_string()}/

      assert Regex.match?(regex, "P@ssword1!")
    end

    test "returns a regex string that does not match passwords that are shorter than six characters" do
      regex = ~r/#{PasswordHelper.password_regex_string()}/

      refute Regex.match?(regex, "P@ssw")
    end

    test "returns a regex string that does not match passwords without a number or special character" do
      regex = ~r/#{PasswordHelper.password_regex_string()}/

      refute Regex.match?(regex, "Password")
    end
  end
end
