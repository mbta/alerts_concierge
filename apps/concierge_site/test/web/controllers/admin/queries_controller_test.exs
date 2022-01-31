defmodule ConciergeSite.Admin.QueriesControllerTest do
  use ConciergeSite.ConnCase, async: true

  alias AlertProcessor.Model.Query

  setup %{conn: conn} do
    admin = insert(:user, role: "admin")
    {:ok, conn: guardian_login(admin, conn)}
  end

  describe "index/2" do
    test "lists available queries", %{conn: conn} do
      resp = conn |> get(admin_queries_path(conn, :index)) |> html_response(200)

      for %{label: label} <- Query.all(), do: assert(resp =~ label)
    end
  end

  describe "show/2" do
    setup do
      {:ok, query: Query.all() |> hd()}
    end

    test "shows a query", %{conn: conn, query: %{id: id, label: label, query: sql}} do
      resp = conn |> get(admin_queries_path(conn, :show, id)) |> html_response(200)

      assert resp =~ label
      assert resp =~ sql |> String.split("\n") |> hd()
      refute resp =~ "rows returned"
    end

    test "runs a query", %{conn: conn, query: %{id: id}} do
      resp = conn |> get(admin_queries_path(conn, :show, id, action: "run")) |> html_response(200)

      assert resp =~ "rows returned"
    end

    test "exports a query", %{conn: conn, query: %{id: id}} do
      conn = get(conn, admin_queries_path(conn, :show, id, action: "export"))

      assert response(conn, 200) =~ ~r/^(\w+,)*\w+\n/
      assert response_content_type(conn, :csv)
    end
  end
end
