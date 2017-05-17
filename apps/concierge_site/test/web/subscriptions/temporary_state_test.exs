defmodule ConciergeSite.Subscriptions.TemporaryStateTest do
  use ExUnit.Case
  alias ConciergeSite.Subscriptions.TemporaryState

  @test_data %{
    test: "data"
  }

  test "it generates a string token from a map of data" do
    assert is_binary(TemporaryState.encode(@test_data))
  end

  test "it validates a token against a map of data" do
    token = TemporaryState.encode(@test_data)
    assert TemporaryState.valid?(token, @test_data)
  end

  test "it returns invalid if a token does not match data" do
    refute TemporaryState.valid?("Garbage", @test_data)
  end
end
