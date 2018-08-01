defmodule AlertProcessor.Metrics.UserMetricsTest do
  @moduledoc false
  use AlertProcessor.DataCase
  import AlertProcessor.Factory
  alias AlertProcessor.Metrics.UserMetrics

  test "counts_by_type/0" do
    # insert two default users with phone numbers
    insert(:user)
    insert(:user)

    # insert one user without a phone number
    insert(:user, %{phone_number: nil})

    [phone_count, email_count] = UserMetrics.counts_by_type()
    assert phone_count == 2
    assert email_count == 1
  end
end
