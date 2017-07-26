defmodule AlertProcess.Auth.TokenTest do
  use AlertProcessor.DataCase
  import AlertProcessor.Factory

  alias AlertProcessor.Auth.Token

  @seconds_in_day (60 * 60 * 24)

  defp correct_expiration_timestamp?(token_timestamp, days_away) do
    adjusted_expiration_date =
      with {:ok, datetime} <- DateTime.from_unix(token_timestamp),
            naive_datetime <- DateTime.to_naive(datetime),
            adjusted_naive_datetime <- NaiveDateTime.add(naive_datetime, (-days_away * @seconds_in_day)) do
        NaiveDateTime.to_date(adjusted_naive_datetime)
      else
        _ -> :error
      end
    :eq == Date.compare(adjusted_expiration_date, Date.utc_today())
  end

  setup do
    user = insert(:user)

    {:ok, user: user}
  end

  test "issue token", %{user: user} do
    {:ok, _token, claims} = Token.issue(user)
    %{"pem" => %{"default" => permission_number}} = claims
    assert permission_number == Guardian.Permissions.max
  end

  test "issue token sets permissions" , %{user: user} do
    {:ok, _token, claims} = Token.issue(user, [:reset_password])
    %{"pem" => %{"default" => permission_number}} = claims
    assert permission_number != Guardian.Permissions.max
    assert Guardian.Permissions.to_list(permission_number, :default) == [:reset_password]
  end

  test "issue token with ttl", %{user: user} do
    {:ok, _token, claims} = Token.issue(user, {7, :days})
    %{"pem" => %{"default" => permission_number}, "exp" => expiration_unix_timestamp} = claims
    assert permission_number == Guardian.Permissions.max
    assert correct_expiration_timestamp?(expiration_unix_timestamp, 7)
  end

  test "issue token with permissions and ttl", %{user: user} do
    {:ok, _token, claims} = Token.issue(user, [:reset_password], {10, :days})
    %{"pem" => %{"default" => permission_number}, "exp" => expiration_unix_timestamp} = claims
    assert permission_number != Guardian.Permissions.max
    assert Guardian.Permissions.to_list(permission_number, :default) == [:reset_password]
    assert correct_expiration_timestamp?(expiration_unix_timestamp, 10)
  end
end
