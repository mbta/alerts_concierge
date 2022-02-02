defmodule ConciergeSite.Admin.QueriesView do
  use ConciergeSite.Web, :view

  def render("show.csv", %{result: %{columns: columns, rows: rows}}) do
    id_indices = id_indices(columns)

    csv_rows =
      rows
      |> Stream.map(fn row ->
        row |> Enum.map(&format_value(&1, id_indices)) |> Enum.join(",")
      end)
      |> Enum.join("\n")

    Enum.join(columns, ",") <> "\n" <> csv_rows
  end

  defp format_value(value, true) when is_binary(value) do
    case Ecto.UUID.load(value) do
      {:ok, uuid} -> uuid
      {:error, _} -> inspect(value)
    end
  end

  defp format_value(value, false) when is_binary(value), do: value

  defp format_value(%NaiveDateTime{} = value, _) do
    value |> NaiveDateTime.truncate(:second) |> to_string()
  end

  defp format_value(nil, _), do: "null"

  defp format_value(value, _), do: inspect(value)

  defp id_indices(columns) do
    columns
    |> Enum.with_index()
    |> Enum.filter(fn {column, _} -> column == "id" or String.ends_with?(column, "_id") end)
    |> Enum.map(fn {_, index} -> index end)
    |> MapSet.new()
  end
end
