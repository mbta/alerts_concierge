defmodule AlertProcessor.Model.QueryTest do
  @moduledoc false
  use AlertProcessor.DataCase, async: true
  alias AlertProcessor.Model.Query

  test "all queries are valid" do
    for query <- Query.all() do
      assert %Postgrex.Result{command: :select} = Query.execute!(query)
    end
  end
end
