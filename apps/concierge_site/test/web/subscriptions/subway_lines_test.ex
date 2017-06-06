defmodule ConciergeSite.Subscriptions.SubwayLinesTest do
  use ExUnit.Case
  alias ConciergeSite.Subscriptions.SubwayLines

  describe "station_select_list_options" do
    test "changes a map of lines into a keyword list" do
      stations = %{{"Blue", 1} => [], {"Green", 0} => [], {"Red", 0} => []}
      select_options = SubwayLines.station_list_select_options(stations)

      assert select_options == [{"Blue", []}, {"Green", []}, {"Red", []}]
    end
  end
end
