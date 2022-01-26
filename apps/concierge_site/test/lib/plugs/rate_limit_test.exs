defmodule ConciergeSite.Plugs.RateLimitTest do
  @moduledoc false
  use ExUnit.Case
  use Plug.Test

  alias ConciergeSite.Plugs.RateLimit

  setup do
    on_exit(fn ->
      # https://github.com/ExHammer/hammer/issues/35
      true = :ets.delete_all_objects(:hammer_ets_buckets)
    end)
  end

  defp conn_with_ip(method, remote_ip \\ {127, 0, 0, 1}) do
    %{(conn(method, "/") |> assign(:rate_limit?, true)) | remote_ip: remote_ip}
  end

  defp conn_with_user(method, user_id) do
    conn(method, "/") |> assign(:rate_limit?, true) |> assign(:current_user, %{id: user_id})
  end

  defp call(conn), do: RateLimit.call(conn, RateLimit.init([]))

  test "does not limit GET requests" do
    for _ <- 1..100 do
      conn = conn_with_ip(:get)
      assert call(conn) == conn
    end
  end

  test "limits non-GET requests by remote IP" do
    for _ <- 1..5 do
      conn = conn_with_ip(:post)
      assert call(conn) == conn
    end

    assert %{status: 429, halted: true} = conn_with_ip(:post) |> call()

    other_ip_conn = conn_with_ip(:post, {10, 0, 0, 1})
    assert call(other_ip_conn) == other_ip_conn
  end

  test "limits signed-in non-GET requests by user ID" do
    for _ <- 1..15 do
      conn = conn_with_user(:post, 1)
      assert call(conn) == conn
    end

    assert %{status: 429, halted: true} = conn_with_user(:post, 1) |> call()

    other_user_conn = conn_with_user(:post, 2)
    assert call(other_user_conn) == other_user_conn
  end
end
