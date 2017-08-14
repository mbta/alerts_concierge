defmodule ConciergeSite.PaginationHelpersTest do
  use ConciergeSite.ConnCase
  alias ConciergeSite.PaginationHelpers

  describe "paginate/2" do
    test "only one page" do
      conn = build_conn(:get, "/test_path")
      page = %Scrivener.Page{page_number: 1, total_pages: 1, entries: [1, 2, 3]}
      pagination = conn |> PaginationHelpers.paginate(page) |> Phoenix.HTML.safe_to_string()
      assert pagination =~ "1 of 1"
      refute pagination =~ "?page=0"
      refute pagination =~ "?page=2"
    end

    test "first of multiple pages" do
      conn = build_conn(:get, "/test_path", %{"page" => "1"})
      page = %Scrivener.Page{page_number: 1, total_pages: 3, entries: [1, 2, 3]}
      pagination = conn |> PaginationHelpers.paginate(page) |> Phoenix.HTML.safe_to_string()
      assert pagination =~ "1 of 3"
      assert pagination =~ "?page=2"
      refute pagination =~ "?page=0"
    end

    test "middle of multiple pages" do
      conn = build_conn(:get, "/test_path", %{"page" => "2"})
      page = %Scrivener.Page{page_number: 2, total_pages: 3, entries: [1, 2, 3]}
      pagination = conn |> PaginationHelpers.paginate(page) |> Phoenix.HTML.safe_to_string()
      assert pagination =~ "2 of 3"
      assert pagination =~ "?page=1"
      assert pagination =~ "?page=3"
    end

    test "last of multiple pages" do
      conn = build_conn(:get, "/test_path", %{"page" => "3"})
      page = %Scrivener.Page{page_number: 3, total_pages: 3, entries: [1, 2, 3]}
      pagination = conn |> PaginationHelpers.paginate(page) |> Phoenix.HTML.safe_to_string()
      assert pagination =~ "3 of 3"
      assert pagination =~ "?page=2"
      refute pagination =~ "?page=4"
    end
  end
end
