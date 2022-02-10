defmodule AlertProcessor.Helpers.DateTimeHelperTest do
  @moduledoc false
  use ExUnit.Case, async: true
  alias AlertProcessor.Helpers.DateTimeHelper, as: DTH

  describe "parse_unix_timestamp/2" do
    test "parses a unix timestamp with the default time zone" do
      {:ok, datetime} = DTH.parse_unix_timestamp(1_500_306_651)
      assert datetime == DateTime.from_naive!(~N[2017-07-17 11:50:51], "America/New_York")
    end

    test "parses a unix timestamp with the given time zone" do
      {:ok, datetime} = DTH.parse_unix_timestamp(1_500_306_651, "Etc/UTC")
      assert datetime == ~U[2017-07-17 15:50:51Z]
    end

    test "returns :error when the timestamp can't be parsed" do
      assert :error == DTH.parse_unix_timestamp(-218_937_198_213_123)
    end

    test "returns :error when the given time zone can't be parsed" do
      assert :error == DTH.parse_unix_timestamp(1_500_306_651, "not a time zone")
    end
  end
end
