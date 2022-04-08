defmodule AlertProcessor.Helpers.SortTest do
  use ExUnit.Case, async: true
  alias AlertProcessor.Helpers.Sort

  describe "nils_last/1" do
    test "sorts nils to end" do
      list = [5, nil, 10, nil, 1, nil, 6]
      sorted = Enum.sort(list, Sort.nils_last())

      assert sorted == [1, 5, 6, 10, nil, nil, nil]
    end

    test "parameterized by sorter" do
      list = [5, nil, 10, nil, 1, nil, 6]
      sorted = Enum.sort(list, Sort.nils_last(&>=/2))

      assert sorted == [10, 6, 5, 1, nil, nil, nil]
    end
  end
end
