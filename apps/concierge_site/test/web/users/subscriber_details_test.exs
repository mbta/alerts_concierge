defmodule ConciergeSite.SubscriberDetailsTest do
  use ConciergeSite.DataCase

  alias AlertProcessor.Model.{Subscription, User}
  alias AlertProcessor.Subscription.{AmenitiesMapper, CommuterRailMapper}
  alias ConciergeSite.{SubscriberDetails, UserParams}
  import AlertProcessor.Factory

  setup do
    {:ok, user} = User.create_account(%{"email" => "test_email@whatever.com", "password" => "Password1", "password_confirmation" => "Password1"})
    {:ok, start_time} = Time.new(12, 0, 0)
    {:ok, end_time} = Time.new(12, 0, 0)
    one_way_params = %{
      "origin" => "Anderson/ Woburn",
      "destination" => "place-north",
      "trips" => ["123", "125"],
      "relevant_days" => ["saturday"],
      "departure_start" => start_time,
      "departure_end" => end_time,
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
      assert changelog =~ "#{user.email} updated do_not_disturb_end from  7:00 AM to N/A, do_not_disturb_start from 10:00 PM to N/A, phone_number from N/A to 5551231234"
    end

    test "maps setting vacation", %{user: user} do
      {:ok, vacation_dates} = UserParams.convert_vacation_strings_to_datetimes(%{"vacation_start" => "01/01/2020", "vacation_end" => "01/01/2030"})
      User.update_vacation(user, vacation_dates, user.id)
      changelog = user.id |> SubscriberDetails.changelog() |> changelog_to_binary()
      assert changelog =~ "#{user.email} updated vacation_end from N/A to 01/01/2030, vacation_start from N/A to 01/01/2020"
    end

    test "maps updating password", %{user: user} do
      User.update_password(user, %{"password" => "newp4assword1", "password_confirmation" => "newp4assword1"}, user)
      changelog = user.id |> SubscriberDetails.changelog() |> changelog_to_binary()
      assert changelog =~ "#{user.email} updated their password"
    end

    test "maps disabling account", %{user: user} do
      User.disable_account(user, user)
      changelog = user.id |> SubscriberDetails.changelog() |> changelog_to_binary()
      assert changelog =~ "#{user.email} disabled their account"
    end

    test "maps sms opt out", %{user: user} do
      User.put_users_on_indefinite_vacation([user.id], "sms-opt-out")
      changelog = user.id |> SubscriberDetails.changelog() |> changelog_to_binary()
      assert changelog =~ "Account put in indefinite vacation mode due to sms opt out."
    end

    test "email unsubscribe", %{user: user} do
      User.put_user_on_indefinite_vacation(user, "email-unsubscribe")
      changelog = user.id |> SubscriberDetails.changelog() |> changelog_to_binary()
      assert changelog =~ "Account put in indefinite vacation mode due to email unsubscribe."
    end

    test "email complaint received", %{user: user} do
      User.put_user_on_indefinite_vacation(user, "email-complaint-received")
      changelog = user.id |> SubscriberDetails.changelog() |> changelog_to_binary()
      assert changelog =~ "Account put in indefinite vacation mode due to email complaint received."
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
      {:ok, start_time} = Time.new(10, 0, 0)
      {:ok, end_time} = Time.new(11, 0, 0)
      params = %{
        "alert_priority_type" => :high,
        "start_time" => start_time,
        "end_time" => end_time,
        "trips" => ["123", "127"]
      }
      multi = CommuterRailMapper.build_update_subscription_transaction(subscription, params, user.id)
      Repo.transaction(multi)
      changelog = user.id |> SubscriberDetails.changelog() |> changelog_to_binary()
      assert changelog =~ "#{user.email} removed trip 123 from subscription #{subscription.id}"
      assert changelog =~ "#{user.email} added trip 123 to subscription #{subscription.id}"
      assert changelog =~ "#{user.email} removed trip 125 from subscription #{subscription.id}"
      assert changelog =~ "#{user.email} added trip 127 to subscription #{subscription.id}"
      assert changelog =~ "#{user.email} updated alert_priority_type from low to high, end_time from 12:00pm to 11:00am, start_time from 12:00pm to 10:00am for subscription #{subscription.id}"
    end

    test "maps updating amenities", %{user: user} do
      params = %{
        "amenities" => ["elevator"],
        "stops" => ["place-north", "place-sstat"],
        "routes" => ["red"],
        "relevant_days" => ["weekday"]
      }
      {:ok, subscription_infos} = AmenitiesMapper.map_subscriptions(params)
      multi = AmenitiesMapper.build_subscription_transaction(subscription_infos, user, user.id)
      Repo.transaction(multi)
      subscription = Repo.one(from s in Subscription, where: s.user_id == ^user.id and s.type == "amenity", preload: [:informed_entities])
      {:ok, subscription_infos} = AmenitiesMapper.map_subscriptions(Map.put(params, "stops", ["place-sstat"]))
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

    test "does not show admin:view-subscriber" do
      user = insert(:user)
      admin_user = insert(:user, role: "application_administration")
      User.log_admin_action(:view_subscriber, admin_user, user)
      changelog = user.id |> SubscriberDetails.changelog()
      assert changelog == []
    end

    test "does not show admin:message-subscriber" do
      user = insert(:user)
      admin_user = insert(:user, role: "application_administration")
      User.log_admin_action(:view_subscriber, admin_user, user)
      changelog = user.id |> SubscriberDetails.changelog()
      assert changelog == []
    end

    test "does not show admin:impersonate-subscriber" do
      user = insert(:user)
      admin_user = insert(:user, role: "application_administration")
      User.log_admin_action(:view_subscriber, admin_user, user)
      changelog = user.id |> SubscriberDetails.changelog()
      assert changelog == []
    end

    test "does not show updates to subscriber account with no changes" do
      user = insert(:user)
      User.update_account(user, %{}, user.id)
      changelog = user.id |> SubscriberDetails.changelog()
      assert changelog == []
    end
  end

  describe "notification_timeline" do
    test "works for notificaiton with description" do
      user = insert(:user)
      notification = insert(:notification, user: user, alert_id: "123", status: :sent, email: user.email)
      changelog = user |> SubscriberDetails.notification_timeline() |> changelog_to_binary()
      assert changelog =~ "Email sent to: #{user.email} -- #{notification.service_effect} #{notification.header} #{notification.description}"
    end

    test "works for notification without description" do
      user = insert(:user)
      notification = insert(:notification, user: user, alert_id: "123", status: :sent, email: user.email, description: nil)
      changelog = user |> SubscriberDetails.notification_timeline() |> changelog_to_binary()
      assert changelog =~ "Email sent to: #{user.email} -- #{notification.service_effect} #{notification.header} "
    end
  end

  defp changelog_to_binary(changelog) do
    changelog |> Enum.flat_map(fn({_date, change_info}) -> change_info end) |> Enum.map(fn({_time, change_info}) -> change_info end) |> IO.iodata_to_binary()
  end
end
