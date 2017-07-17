defmodule ConciergeSite.AmenitySubscriptionViewTest do
  use ExUnit.Case
  alias ConciergeSite.AmenitySubscriptionView
  alias AlertProcessor.Model.{Subscription, InformedEntity}

  @informed_entities [
    %InformedEntity{
      facility_type: :escalator,
      stop: "place-nquincy"
    },
    %InformedEntity{
      facility_type: :elevator,
      route: "Green"
    }
  ]

  @subscription %Subscription{
    informed_entities: @informed_entities,
    relevant_days: [:saturday, :weekday]
  }

  describe "amenity_facility_type/1" do
    test "it returns ampersand separated list of amenities" do
      result =
        @subscription
        |> AmenitySubscriptionView.amenity_facility_type()
        |> IO.iodata_to_binary
      assert result == "Escalator & Elevator"
    end
  end

  describe "amenity_schedule/1" do
    test "it returns the schedule details" do
      result =
        @subscription
        |> AmenitySubscriptionView.amenity_schedule()
        |> IO.iodata_to_binary

      assert result == "1 station + Green Line on Saturdays, Weekdays"
    end

    test "pluralizes stops" do
      informed_entity = %InformedEntity{
        facility_type: :escalator,
        stop: "place-harvard"
      }
      ies = @informed_entities ++ [informed_entity]
      sub = Map.put(@subscription, :informed_entities, ies)
      result =
        sub
        |> AmenitySubscriptionView.amenity_schedule()
        |> IO.iodata_to_binary

      assert result == "2 stations + Green Line on Saturdays, Weekdays"
    end
  end
end
