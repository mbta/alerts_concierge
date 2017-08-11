defmodule ConciergeSite.PaginationHelpersTest do
  use ConciergeSite.ConnCase
  alias ConciergeSite.PaginationHelpers

  describe "paginate/2" do
    test "only one page" do
      conn = build_conn(:get, "/test_path")
      page = %Scrivener.Page{page_number: 1, total_pages: 1, entries: [1, 2, 3]}
      {:safe, pagination} = PaginationHelpers.paginate(conn, page)
      assert IO.iodata_to_binary(pagination) =~ "1 of 1"
      refute IO.iodata_to_binary(pagination) =~ "?page=0"
      refute IO.iodata_to_binary(pagination) =~ "?page=2"
    end

    test "first of multiple pages" do
      conn = build_conn(:get, "/test_path", %{"page" => "1"})
      page = %Scrivener.Page{page_number: 1, total_pages: 3, entries: [1, 2, 3]}
      {:safe, pagination} = PaginationHelpers.paginate(conn, page)
      assert IO.iodata_to_binary(pagination) =~ "1 of 3"
      assert IO.iodata_to_binary(pagination) =~ "?page=2"
      refute IO.iodata_to_binary(pagination) =~ "?page=0"
    end

    test "middle of multiple pages" do
      conn = build_conn(:get, "/test_path", %{"page" => "2"})
      page = %Scrivener.Page{page_number: 2, total_pages: 3, entries: [1, 2, 3]}
      {:safe, pagination} = PaginationHelpers.paginate(conn, page)
      assert IO.iodata_to_binary(pagination) =~ "2 of 3"
      assert IO.iodata_to_binary(pagination) =~ "?page=1"
      assert IO.iodata_to_binary(pagination) =~ "?page=3"
    end

    test "last of multiple pages" do
      conn = build_conn(:get, "/test_path", %{"page" => "3"})
      page = %Scrivener.Page{page_number: 3, total_pages: 3, entries: [1, 2, 3]}
      {:safe, pagination} = PaginationHelpers.paginate(conn, page)
      assert IO.iodata_to_binary(pagination) =~ "3 of 3"
      assert IO.iodata_to_binary(pagination) =~ "?page=2"
      refute IO.iodata_to_binary(pagination) =~ "?page=4"
    end
  end
end
