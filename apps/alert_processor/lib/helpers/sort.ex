defmodule AlertProcessor.Helpers.Sort do
  @moduledoc """
  Helpers for sorting
  """

  @doc """
  Wraps a sorting function such that `nil`s are sorted to the end
  """
  @spec nils_last((term(), term() -> boolean())) :: (term(), term() -> boolean())
  def nils_last(sorter \\ &<=/2) do
    fn
      _, nil -> true
      nil, _ -> false
      a, b -> sorter.(a, b)
    end
  end
end
