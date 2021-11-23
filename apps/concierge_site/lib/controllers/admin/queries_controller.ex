defmodule ConciergeSite.Admin.QueriesController do
  use ConciergeSite.Web, :controller

  alias AlertProcessor.Repo
  alias AlertProcessor.Model.SavedQuery
  alias Ecto.Changeset

  def index(conn, _params) do
    render(conn, "index.html", queries: SavedQuery.all())
  end

  def new(conn, _params) do
    render(conn, "new.html", changeset: SavedQuery.changeset(%SavedQuery{}), result: nil)
  end

  def create(conn, %{"action" => "run", "saved_query" => params}) do
    {changeset, result} = apply_and_run(%SavedQuery{}, params)
    render(conn, "new.html", changeset: changeset, result: result)
  end

  def create(conn, %{"action" => "save", "saved_query" => params}) do
    %SavedQuery{}
    |> SavedQuery.changeset(params)
    |> Repo.insert()
    |> handle_save(conn, "new.html")
  end

  def edit(conn, %{"id" => id}) do
    query = Repo.get!(SavedQuery, id)
    render(conn, "edit.html", id: id, changeset: SavedQuery.changeset(query), result: nil)
  end

  def update(conn, %{"id" => id, "action" => "run", "saved_query" => params}) do
    {changeset, result} = apply_and_run(Repo.get!(SavedQuery, id), params)
    render(conn, "edit.html", id: id, changeset: changeset, result: result)
  end

  def update(conn, %{"id" => id, "action" => "save", "saved_query" => params}) do
    Repo.get!(SavedQuery, id)
    |> SavedQuery.changeset(params)
    |> Repo.update()
    |> handle_save(conn, "edit.html")
  end

  def delete(conn, %{"id" => id}) do
    Repo.get!(SavedQuery, id) |> Repo.delete!()

    conn
    |> put_flash(:info, "Query deleted.")
    |> redirect(to: admin_queries_path(conn, :index))
  end

  defp apply_and_run(query, params) do
    changeset = SavedQuery.changeset(query, params)
    {_, result} = changeset |> Changeset.apply_changes() |> SavedQuery.execute()
    {changeset, result}
  end

  defp errors(changeset) do
    changeset
    |> Changeset.traverse_errors(&elem(&1, 0))
    |> Enum.flat_map(fn {field, errors} -> Enum.map(errors, &"#{field} #{&1}") end)
    |> Enum.join(", ")
  end

  defp handle_save({:ok, %{id: id}}, conn, _template) do
    conn
    |> put_flash(:info, "Query saved.")
    |> redirect(to: admin_queries_path(conn, :edit, id))
  end

  defp handle_save({:error, changeset}, conn, template) do
    conn
    |> put_flash(:error, "Error: #{errors(changeset)}")
    |> render(template, id: changeset.data.id, changeset: changeset, result: nil)
  end
end
