defmodule ConciergeSite.FerrySubscriptionViewTest do
  use ExUnit.Case
  alias ConciergeSite.FerrySubscriptionView

  describe "progress_link_class" do
    test "it returns the disabled class when the page is trip_type" do
      class = FerrySubscriptionView.progress_link_class(:trip_type, :trip_info)
      assert class == "disabled-progress-link"
    end

    test "it returns the disabled class when the page/step are included in disabled_progress_bar_links" do
      class = FerrySubscriptionView.progress_link_class(:trip_info, :preferences)
      assert class == "disabled-progress-link"
    end

    test "it returns nil otherwise" do
      class = FerrySubscriptionView.progress_link_class(:trip_info, :trip_type)
      assert class == nil
    end
  end

  describe "progress_step_classes" do

    @active_classes %{circle: "active-circle", name: "active-page"}

    test "it returns a map of active classes when step and page are equal" do
      classes = FerrySubscriptionView.progress_step_classes(:trip_info, :trip_info)
      assert classes == @active_classes
    end

    test "it returns an empty map when step is ahead of current page" do
      classes = FerrySubscriptionView.progress_step_classes(:trip_type, :preferences)
      assert classes == %{}
    end
  end
end
