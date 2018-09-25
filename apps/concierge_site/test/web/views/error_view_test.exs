defmodule ConciergeSite.ErrorViewTest do
  use ConciergeSite.ConnCase, async: true

  # Bring render/3 and render_to_string/3 for testing custom views
  import Phoenix.View

  setup do
    conn = get(build_conn(), "/")
    {:ok, conn: conn}
  end

  test "renders 404.html", %{conn: conn} do
    assert render_to_string(ConciergeSite.ErrorView, "404.html", conn: conn) =~
             "Oops! This stop can not be found."
  end

  test "renders 403.html", %{conn: conn} do
    assert render_to_string(ConciergeSite.ErrorView, "403.html", conn: conn) =~
             "Your stop requires admin permission. This page is forbidden."
  end

  test "render 500.html", %{conn: conn} do
    assert render_to_string(ConciergeSite.ErrorView, "500.html", conn: conn) =~
             "Sorry, we’re currently out of service"
  end

  test "render any other", %{conn: conn} do
    assert render_to_string(ConciergeSite.ErrorView, "505.html", conn: conn) =~
             "Sorry, we’re currently out of service"
  end
end
