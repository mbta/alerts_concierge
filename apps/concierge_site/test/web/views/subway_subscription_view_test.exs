defmodule ConciergeSite.SubwaySubscriptionViewTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  alias ConciergeSite.SubwaySubscriptionView

  describe "progress_link_class" do
    test "it returns the disabled class when the page is trip_type" do
      class = SubwaySubscriptionView.progress_link_class(:trip_type, :trip_info)
      assert class == "disabled-progress-link"
    end

    test "it returns the disabled class when the page/step are included in disabled_progress_bar_links" do
      class = SubwaySubscriptionView.progress_link_class(:trip_info, :preferences)
      assert class == "disabled-progress-link"
    end

    test "it returns nil otherwise" do
      class = SubwaySubscriptionView.progress_link_class(:trip_info, :trip_type)
      assert class == nil
    end
  end

  describe "progress_step_classes" do

    @active_classes %{circle: "active-circle", name: "active-page"}

    test "it returns a map of active classes when step and page are equal" do
      classes = SubwaySubscriptionView.progress_step_classes(:trip_info, :trip_info)
      assert classes == @active_classes
    end

    test "it returns an empty map when step is ahead of current page" do
      classes = SubwaySubscriptionView.progress_step_classes(:trip_type, :preferences)
      assert classes == %{}
    end
  end

  describe "trip_summary_title" do
    test "it returns a summary of the selected params for a round trip" do
      use_cassette "service_info", custom: true, clear_mock: true, match_requests_on: [:query] do
        params = %{
          "departure_start" => "08:45:00",
          "departure_end" => "09:15:00",
          "origin" => "place-buest",
          "destination" => "place-buwst",
          "saturday" => "true",
          "sunday" => "true",
          "weekday" => "false",
          "trip_type" => "round_trip",
        }

        station_names = %{"origin" => "Boston Univ. East", "destination" => "Boston Univ. West"}

        trip_summary_title =
          params
          |> SubwaySubscriptionView.trip_summary_title(station_names)
          |> IO.iodata_to_binary()

        assert trip_summary_title == "Round trip Saturday or Sunday travel between Boston Univ. East and Boston Univ. West"
      end
    end

    test "it returns a summary of the selected params for general travel" do
      use_cassette "service_info", custom: true, clear_mock: true, match_requests_on: [:query] do
        params = %{
          "departure_start" => "16:00:00",
          "departure_end" => "23:45:00",
          "origin" => "place-buest",
          "destination" => "place-buwst",
          "saturday" => "true",
          "sunday" => "true",
          "weekday" => "true",
          "trip_type" => "roaming",
        }

        station_names = %{"origin" => "Boston Univ. East", "destination" => "Boston Univ. West"}

        trip_summary_title =
          params
          |> SubwaySubscriptionView.trip_summary_title(station_names)
          |> IO.iodata_to_binary()

        assert trip_summary_title == "Saturday, Sunday, or weekday general travel between Boston Univ. East and Boston Univ. West"
      end
    end

    test "it returns a summary including stations, days, and times for one way trips" do
      use_cassette "service_info", custom: true, clear_mock: true, match_requests_on: [:query] do
        params = %{
          "departure_start" => "08:45:00",
          "departure_end" => "09:15:00",
          "origin" => "place-buest",
          "destination" => "place-buwst",
          "saturday" => "false",
          "sunday" => "false",
          "weekday" => "true",
          "trip_type" => "one_way",
        }

        station_names = %{"origin" => "Boston Univ. East", "destination" => "Boston Univ. West"}

        trip_summary_title = params
          |> SubwaySubscriptionView.trip_summary_title(station_names)
          |> IO.iodata_to_binary()

        assert trip_summary_title == "Boston Univ. East to Boston Univ. West, weekdays 8:45 AM - 9:15 AM"
      end
    end
  end

  describe "trip_summary_logistics" do
    test "it returns a summary of the selected trips" do
      use_cassette "service_info", custom: true, clear_mock: true, match_requests_on: [:query] do
        params = %{
          "departure_start" => "09:45:00",
          "departure_end" => "10:15:00",
          "return_start" => "17:45:00",
          "return_end" => "18:15:00",
          "origin" => "place-brntn",
          "destination" => "place-qamnl",
          "saturday" => "true",
          "sunday" => "false",
          "weekday" => "false",
          "trip_type" => "round_trip",
        }

        station_names = %{"origin" => "Braintree", "destination" => "Quincy Adams"}

        trip_summary_logistics = params
          |> SubwaySubscriptionView.trip_summary_logistics(station_names)
          |> Enum.map(&IO.iodata_to_binary/1)

        assert trip_summary_logistics ==
          ["9:45 AM - 10:15 AM from Braintree to Quincy Adams",
           "5:45 PM - 6:15 PM from Quincy Adams to Braintree"]
      end
    end
  end
end
