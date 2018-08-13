defmodule ConciergeSite.ErrorViewTest do
  use ConciergeSite.ConnCase, async: true
  import Phoenix.Controller
  import Phoenix.View, only: [render_to_string: 3]

  setup do
    conn = get(build_conn(), "/")
    {:ok, conn: conn}
  end

  test "renders 404.html", %{conn: conn} do
    assert render_to_string(ConciergeSite.ErrorView, "404.html", conn: conn) =~
             "Your stop cannot be found. This page is no longer in service."
  end

  test "renders 403.html", %{conn: conn} do
    assert render_to_string(ConciergeSite.ErrorView, "403.html", conn: conn) =~
             "Your stop requires admin permission. This page is forbidden."
  end

  test "render 500.html", %{conn: conn} do
    assert render_to_string(ConciergeSite.ErrorView, "500.html", conn: conn) ==
             "Internal server error"
  end

  test "render any other", %{conn: conn} do
    assert render_to_string(ConciergeSite.ErrorView, "505.html", conn: conn) ==
             "Internal server error"
  end

  test "render 500.html with a layout" do
    # mimick the pipeline RenderErrors
    conn =
      Phoenix.ConnTest.build_conn()
      |> accepts(["html"])
      |> put_private(:phoenix_endpoint, ConciergeSite.Endpoint)
      |> put_layout({ConciergeSite.LayoutView, "app.html"})
      |> put_view(ConciergeSite.ErrorView)
      |> put_status(500)

    conn = render(conn, :"500", conn: conn)

    assert html_response(conn, 500) =~ "Internal server error"
  end
end
