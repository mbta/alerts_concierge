defmodule ConciergeSite.HealthControllerTest do
  @moduledoc false
  use ConciergeSite.ConnCase, async: true

  describe "index/2" do
    test "returns 200", %{conn: conn} do
      assert %{status: 200} = get(conn, "/_health")
    end
  end
end
