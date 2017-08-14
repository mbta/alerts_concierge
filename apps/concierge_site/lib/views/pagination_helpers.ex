defmodule ConciergeSite.PaginationHelpers do
  @moduledoc """
  Conveniences for adding pagination into templates.
  """

  use Phoenix.HTML

  @doc """
  Generates pagination information
  """
  def paginate(_conn, %Scrivener.Page{page_number: 1, total_pages: 1}) do
    content_tag :div, class: "admin-pagination" do
      "1 of 1"
    end
  end
  def paginate(conn, %Scrivener.Page{page_number: 1, total_pages: total_pages}) do
    content_tag :div, class: "admin-pagination" do
      [
        content_tag(:span, ["1 of ", to_string(total_pages)]),
        content_tag(:i, "", class: "fa fa-chevron-left disabled"),
        link(content_tag(:i, "", class: "fa fa-chevron-right"), to: encode_params(Map.put(conn.params, "page", 2)))
      ]
    end
  end
  def paginate(conn, %Scrivener.Page{page_number: total_pages, total_pages: total_pages}) do
    content_tag :div, class: "admin-pagination" do
      [
        content_tag(:span, [to_string(total_pages), " of ", to_string(total_pages)]),
        link(content_tag(:i, "", class: "fa fa-chevron-left"), to: encode_params(Map.put(conn.params, "page", total_pages - 1))),
        content_tag(:i, "", class: "fa fa-chevron-right disabled")
      ]
    end
  end
  def paginate(conn, %Scrivener.Page{page_number: page_number, total_pages: total_pages}) do
    content_tag :div, class: "admin-pagination" do
      [
        content_tag(:span, [to_string(page_number), " of ", to_string(total_pages)]),
        link(content_tag(:i, "", class: "fa fa-chevron-left"), to: encode_params(Map.put(conn.params, "page", page_number - 1))),
        link(content_tag(:i, "", class: "fa fa-chevron-right"), to: encode_params(Map.put(conn.params, "page", page_number + 1)))
      ]
    end
  end

  defp encode_params(params) do
    "?" <> Plug.Conn.Query.encode(Map.to_list(params))
  end
end
