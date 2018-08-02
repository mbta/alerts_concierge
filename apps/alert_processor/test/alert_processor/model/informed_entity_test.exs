defmodule AlertProcessor.Model.InformedEntityTest do
  use ExUnit.Case
  alias AlertProcessor.Model.InformedEntity

  describe "entity_type/1" do
    test "it identifies an amenity" do
      assert :amenity =
               InformedEntity.entity_type(%InformedEntity{
                 facility_type: :elevator,
                 stop: "place-davis"
               })
    end

    test "it identifies a stop" do
      assert :stop =
               InformedEntity.entity_type(%InformedEntity{
                 route: "Red",
                 route_type: 1,
                 stop: "place-davis"
               })
    end

    test "it identifies a trip" do
      assert :trip =
               InformedEntity.entity_type(%InformedEntity{
                 route: "CR-Lowell",
                 route_type: 2,
                 trip: "CR-Weekday-Spring-17-336"
               })
    end

    test "it identifies a route" do
      assert :route = InformedEntity.entity_type(%InformedEntity{route: "Red", route_type: 1})

      assert :route =
               InformedEntity.entity_type(%InformedEntity{
                 route: "Red",
                 route_type: 1,
                 direction_id: 0
               })

      assert :route =
               InformedEntity.entity_type(%InformedEntity{
                 route: "Red",
                 route_type: 1,
                 direction_id: 1
               })
    end

    test "it identifies a mode" do
      assert :mode = InformedEntity.entity_type(%InformedEntity{route_type: 1})
    end

    test "it fails to identify unknown" do
      assert :unknown = InformedEntity.entity_type(%InformedEntity{})
    end
  end
end
