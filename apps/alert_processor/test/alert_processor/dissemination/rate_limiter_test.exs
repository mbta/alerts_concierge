defmodule AlertProcessor.RateLimiterTest do
  use ExUnit.Case
  alias AlertProcessor.RateLimiter

  setup_all do
    Application.put_env(:alert_processor, :rate_limit_scale, "1000000")
    Application.put_env(:alert_processor, :rate_limit, "1")

    :ok
  end

  describe "check_rate_limit/1" do
    test "Returns :ok if user has not exceeded rate limit" do
      assert RateLimiter.check_rate_limit("user_id_1") == :ok
    end

    test "Returns error if user over rate limit" do
      RateLimiter.check_rate_limit("fast_user")
      assert RateLimiter.check_rate_limit("fast_user") == {:error, :rate_exceeded}
    end
  end
end
