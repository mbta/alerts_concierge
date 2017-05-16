defmodule MbtaServer.QueryHelper do
  import Ecto.Query
  alias MbtaServer.AlertProcessor.Repo

  def execute_query(query) do
    Repo.all(from q in subquery(query), distinct: true, select: q.id)
  end

  def generate_query(module, id_array) do
    Ecto.Query.from(s in module, where: s.id in ^id_array)
  end
end
