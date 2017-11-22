defmodule ConciergeSite.Dissemination.NullAdapterTest do
  use ExUnit.Case
  alias ConciergeSite.Dissemination.NullAdapter

  test "deliver/2" do
    assert NullAdapter.deliver("email", "config") == %{email: "email", config: "config"}
  end

  test "handle_config/1" do
    assert NullAdapter.handle_config("config") == "config"
  end
end
