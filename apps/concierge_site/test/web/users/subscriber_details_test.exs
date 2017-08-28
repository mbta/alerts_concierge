defmodule ConciergeSite.SubscriberDetailsTest do
  use ConciergeSite.DataCase

  alias AlertProcessor.Model.{Subscription, User}
  alias AlertProcessor.Subscription.{AmenitiesMapper, CommuterRailMapper}
  alias ConciergeSite.SubscriberDetails

  setup do
    {:ok, user} = User.create_account(%{"email" => "test_email@whatever.com", "password" => "Password1", "password_confirmation" => "Password1"})
    one_way_params = %{
      "origin" => "Anderson/ Woburn",
      "destination" => "place-north",
      "trips" => ["123", "125"],
      "relevant_days" => ["saturday"],
      "departure_start" => DateTime.from_naive!(~N[2017-07-20 12:00:00], "Etc/UTC"),
      "departure_end" => DateTime.from_naive!(~N[2017-07-20 14:00:00], "Etc/UTC"),
      "return_start" => nil,
      "return_end" => nil,
      "alert_priority_type" => "low",
      "amenities" => ["elevator"]
    }
    {:ok, subscription_infos} = CommuterRailMapper.map_subscriptions(one_way_params)
    multi = CommuterRailMapper.build_subscription_transaction(subscription_infos, user, user.id)
    Repo.transaction(multi)

    {:ok, user: user}
  end

  describe "account" do
    test "maps creation", %{user: user} do
      [{_date, [{_time, account_creation_log} | _]} | _] = SubscriberDetails.changelog(user.id)
      assert account_creation_log =~ "Account created"
    end

    test "maps updating", %{user: user} do
      User.update_account(user, %{"phone_number" => "5551231234", "do_not_disturb_end" => nil, "do_not_disturb_start" => nil}, user.id)
      changelog = user.id |> SubscriberDetails.changelog() |> changelog_to_binary()
      assert changelog =~ "#{user.email} updated do_not_disturb_end from 07:00:00 to N/A, do_not_disturb_start from 22:00:00 to N/A, phone_number from N/A to 5551231234"
    end
  end

  describe "subscription" do
    test "maps creation", %{user: user} do
      subscription = Repo.one(from s in Subscription, where: s.user_id == ^user.id)
      changelog = user.id |> SubscriberDetails.changelog() |> changelog_to_binary()
      assert changelog =~ "#{user.email} created commuter_rail subscription #{subscription.id}"
      assert changelog =~ " between #{subscription.origin} and #{subscription.destination}"
    end

    test "maps updating", %{user: user} do
      subscription = Repo.one(from s in Subscription, where: s.user_id == ^user.id, preload: [:informed_entities])
      params = %{
        "alert_priority_type" => :high,
        "start_time" => DateTime.from_naive!(~N[2017-07-20 12:00:00], "Etc/UTC"),
        "end_time" => DateTime.from_naive!(~N[2017-07-20 15:00:00], "Etc/UTC"),
        "trips" => ["123", "127"]
      }
      multi = CommuterRailMapper.build_update_subscription_transaction(subscription, params, user.id)
      Repo.transaction(multi)
      changelog = user.id |> SubscriberDetails.changelog() |> changelog_to_binary()
      assert changelog =~ "#{user.email} removed trip 123 from subscription #{subscription.id}"
      assert changelog =~ "#{user.email} added trip 123 to subscription #{subscription.id}"
      assert changelog =~ "#{user.email} removed trip 125 from subscription #{subscription.id}"
      assert changelog =~ "#{user.email} added trip 127 to subscription #{subscription.id}"
      assert changelog =~ "#{user.email} updated alert_priority_type from low to high, end_time from 14:00:00 to 15:00:00 for subscription #{subscription.id}"
    end

    test "maps updating amenities", %{user: user} do
      params = %{
        "amenities" => ["elevator"],
        "stops" => "North Station,South Station",
        "routes" => ["red"],
        "relevant_days" => ["weekday"]
      }
      {:ok, subscription_infos} = AmenitiesMapper.map_subscriptions(params)
      multi = AmenitiesMapper.build_subscription_transaction(subscription_infos, user, user.id)
      Repo.transaction(multi)
      subscription = Repo.one(from s in Subscription, where: s.user_id == ^user.id and s.type == "amenity", preload: [:informed_entities])
      {:ok, subscription_infos} = AmenitiesMapper.map_subscriptions(Map.put(params, "stops", "South Station"))
      multi = AmenitiesMapper.build_subscription_update_transaction(subscription, subscription_infos, user.id)
      Repo.transaction(multi)
      changelog = user.id |> SubscriberDetails.changelog() |> changelog_to_binary()
      assert changelog =~ "#{user.email} removed stop place-north from subscription #{subscription.id}"
    end

    test "maps deleting", %{user: user} do
      subscription = Repo.one(from s in Subscription, where: s.user_id == ^user.id, preload: [:informed_entities])
      {:ok, _} = Subscription.delete_subscription(subscription, user.id)
      changelog = user.id |> SubscriberDetails.changelog() |> changelog_to_binary()
      assert changelog =~ "#{user.email} deleted commuter_rail subscription #{subscription.id} between #{subscription.origin} and #{subscription.destination}"
    end
  end

  defp changelog_to_binary(changelog) do
    changelog |> Enum.flat_map(fn({_date, change_info}) -> change_info end) |> Enum.map(fn({_time, change_info}) -> change_info end) |> IO.iodata_to_binary()
  end
end
