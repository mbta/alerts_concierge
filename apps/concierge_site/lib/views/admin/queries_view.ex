defmodule ConciergeSite.Admin.QueriesView do
  use ConciergeSite.Web, :view

  defp format_value(value, true) when is_binary(value) do
    case Ecto.UUID.load(value) do
      {:ok, uuid} -> uuid
      {:error, _} -> inspect(value)
    end
  end

  defp format_value(value, false) when is_binary(value), do: value

  defp format_value({{_, _, _}, {_, _, _, _}} = value, _) do
    case Ecto.DateTime.load(value) do
      {:ok, datetime} -> datetime
      {:error, error} -> inspect(error)
    end
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
