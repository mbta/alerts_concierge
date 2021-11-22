defmodule ConciergeSite.Admin.QueriesController do
  use ConciergeSite.Web, :controller

  alias AlertProcessor.Model.Query

  def index(conn, _params) do
    render(conn, "index.html", queries: Query.all())
  end

  def show(conn, %{"id" => id} = params) do
    query = Query.get(id)

    case Map.get(params, "action") do
      nil ->
        render(conn, "show.html", query: query, result: nil)

      "run" ->
        render(conn, "show.html", query: query, result: Query.execute!(query))

      "export" ->
        render(conn, "show.csv", result: Query.execute!(query))
    end
  end
end
