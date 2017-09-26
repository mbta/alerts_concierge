defmodule AlertProcessor.Subscription.DiagnosticTest do
  @moduledoc false
  use AlertProcessor.DataCase

  alias AlertProcessor.{Subscription.Diagnostic, Model}
  alias Model.{Notification, SavedAlert, Subscription}
  import AlertProcessor.Factory

  @lpn_unix 1497902534
  @alert_params %{
    "active_period" => [%{"start" => 1497902524}],
    "alert_lifecycle" => "ONGOING",
    "cause" => "POLICE_ACTIVITY",
    "cause_detail" => "UNRULY_PASSENGER",
    "created_timestamp" => 1497902534,
    "description_text" => [%{"translation" => %{"language" => "en",
       "text" => "Affected direction: Inbound"}}],
    "duration_certainty" => "UNKNOWN",
    "effect" => "OTHER_EFFECT",
    "effect_detail" => "TRACK_CHANGE",
    "header_text" => [%{"translation" => %{"language" => "en",
        "text" => "Board Needham Line on opposite track due to unruly passenger"}}],
    "id" => "114166",
    "informed_entity" => [%{"activities" => ["BOARD"], "agency_id" => "1",
      "direction_id" => 1, "route_id" => "CR-Needham", "route_type" => 2}],
    "last_modified_timestamp" => @lpn_unix,
    "last_push_notification_timestamp" => @lpn_unix,
    "service_effect_text" => [%{"translation" => %{"language" => "en",
        "text" => "Needham Line track change"}}],
    "severity" => 3,
    "short_header_text" => [%{"translation" => %{"language" => "en",
        "text" => "Board Needham Line on opposite track due to unruly passenger"}}],
    "timeframe_text" => [%{"translation" => %{"language" => "en",
        "text" => "ongoing"}}]
  }

  setup do
    subscriber = build(:user) |> PaperTrail.insert!

    {:ok, date, _} = DateTime.from_iso8601("2017-07-11T01:01:01Z")
    sub_params = params_for(
      :subscription,
      user: subscriber,
      updated_at: date,
      inserted_at: date,
      relevant_days: [:sunday],
      alert_priority_type: :medium,
      type: :bus
    )
    create_changeset = Subscription.create_changeset(%Subscription{}, sub_params)
    inserted_sub = PaperTrail.insert!(create_changeset)

    alert_params =  %{
      alert_id: "114166",
      last_modified: date,
      data: @alert_params
    }

    alert = SavedAlert.save_new_alert(%SavedAlert{}, alert_params)
    {:ok, user: subscriber, subscription: inserted_sub, alert: alert}
  end

  describe "sort/1" do
    test "sorts diagnoses into passed/failed groups" do
      passing = %{
        passed_sent_alert_filter?: true,
        passed_informed_entity_filter?: true,
        passed_severity_filter?: true,
        passed_active_period_filter?: true,
        passes_vacation_period?: true,
        passes_do_not_disturb?: true
      }

      failing = %{
        passed_sent_alert_filter?: false,
        passed_informed_entity_filter?: false,
        passed_severity_filter?: false,
        passed_active_period_filter?: false,
        passes_vacation_period?: false,
        passes_do_not_disturb?: false
      }
      diagnoses = [passing, failing]

      assert Diagnostic.sort(diagnoses) == %{
        all: diagnoses,
        succeeded: [passing],
        failed: [failing]
      }
    end
  end

  describe "diagnose_alert/2" do
    test "alert matched sent alert", %{user: user, alert: alert, subscription: subscription} do
      params = %{
        "alert_date" => %{
          "year" => "2020",
          "month" => "01",
          "day" => "01",
          "hour" => "1",
          "minute" => "1"
        },
        "alert_id" => alert.alert_id
      }

      lpn = DateTime.from_unix!(@lpn_unix)

      notification_params =
        params_for(:notification)
        |> Map.merge(%{
          user_id: user.id,
          alert_id: alert.alert_id,
          status: :sent,
          email: user.email,
          last_push_notification: lpn,
          subscriptions: [subscription]
        })

      %Notification{}
      |> Notification.create_changeset(notification_params)
      |> Repo.insert!

      {:ok, [result]} = Diagnostic.diagnose_alert(user, params)

      assert result.passed_sent_alert_filter? == false
    end

    test "alert did not match sent alert", %{user: user, alert: alert} do
      params = %{
        "alert_date" => %{
          "year" => "2020",
          "month" => "01",
          "day" => "01",
          "hour" => "1",
          "minute" => "1"
        },
        "alert_id" => alert.alert_id
      }

      {:ok, [result]} = Diagnostic.diagnose_alert(user, params)
      assert result.passed_sent_alert_filter? == true
    end

    test "alert matched active period", %{alert: alert, user: user} do
      params = %{
        "alert_date" => %{
          "year" => "2020",
          "month" => "01",
          "day" => "01",
          "hour" => "1",
          "minute" => "1"
        },
        "alert_id" => alert.alert_id
      }

      {:ok, [result]} = Diagnostic.diagnose_alert(user, params)
      assert result.passed_active_period_filter? == true
    end

    test "alert did not match active period", %{user: user} do
      saturday_morning = 1504972475
      saturday_afternoon = 1504983275
      data = Map.put(@alert_params, "active_period", [%{
         "start" => saturday_morning,
         "end" => saturday_afternoon
       }])

      alert_params =  %{
        alert_id: "114167",
        last_modified: DateTime.from_unix!(@lpn_unix),
        data: data
      }

      alert = SavedAlert.save_new_alert(%SavedAlert{}, alert_params)

      params = %{
        "alert_date" => %{
          "year" => "2020",
          "month" => "01",
          "day" => "01",
          "hour" => "1",
          "minute" => "1"
        },
        "alert_id" => alert.alert_id
      }

      {:ok, [result]} = Diagnostic.diagnose_alert(user, params)
      assert result.passed_active_period_filter? == false
    end

    test "alert matched severity", %{user: user} do
      data = Map.put(@alert_params, "severity", 7)

      alert_params =  %{
        alert_id: "114167",
        last_modified: DateTime.from_unix!(@lpn_unix),
        data: data
      }

      alert = SavedAlert.save_new_alert(%SavedAlert{}, alert_params)

      params = %{
        "alert_date" => %{
          "year" => "2020",
          "month" => "01",
          "day" => "01",
          "hour" => "1",
          "minute" => "1"
        },
        "alert_id" => alert.alert_id
      }

      {:ok, [result]} = Diagnostic.diagnose_alert(user, params)
      assert result.passed_severity_filter? == true
    end

    test "alert did not match severity", %{user: user} do
      data = Map.put(@alert_params, "severity", 3)

      alert_params =  %{
        alert_id: "114167",
        last_modified: DateTime.from_unix!(@lpn_unix),
        data: data
      }

      alert = SavedAlert.save_new_alert(%SavedAlert{}, alert_params)

      params = %{
        "alert_date" => %{
          "year" => "2020",
          "month" => "01",
          "day" => "01",
          "hour" => "1",
          "minute" => "1"
        },
        "alert_id" => alert.alert_id
      }

      {:ok, [result]} = Diagnostic.diagnose_alert(user, params)
      assert result.passed_severity_filter? == false
    end

    test "alert matched vacation period" do
      jan_1_2020 = 1577836800
      jan_10_2020 = 1578614400
      jan_11_2020 = 1578700800
      jan_30_2020 = 1580342400
      data = Map.put(@alert_params, "active_period", [%{
         "start" => jan_10_2020,
         "end" => jan_11_2020
       }])

      alert_params =  %{
        alert_id: "114167",
        last_modified: DateTime.from_unix!(@lpn_unix),
        data: data
      }

      alert = SavedAlert.save_new_alert(%SavedAlert{}, alert_params)

      user =
        :user
        |> build(vacation_start: DateTime.from_unix!(jan_1_2020), vacation_end: DateTime.from_unix!(jan_30_2020))
        |> PaperTrail.insert!

        create_changeset = Subscription.create_changeset(
          %Subscription{},
          params_for(:subscription, user: user, relevant_days: [:sunday], type: :bus)
        )
        PaperTrail.insert!(create_changeset)

      params = %{
        "alert_date" => %{
          "year" => "2020",
          "month" => "01",
          "day" => "01",
          "hour" => "1",
          "minute" => "1"
        },
        "alert_id" => alert.alert_id
      }

      {:ok, [result]} = Diagnostic.diagnose_alert(user, params)
      assert result.passes_vacation_period? == false
    end

    test "alert did not match vacation period" do
      saturday_morning = 1504972475
      saturday_afternoon = 1504983275
      data = Map.put(@alert_params, "active_period", [%{
         "start" => saturday_morning,
         "end" => saturday_afternoon
       }])

      alert_params =  %{
        alert_id: "114167",
        last_modified: DateTime.from_unix!(@lpn_unix),
        data: data
      }

      alert = SavedAlert.save_new_alert(%SavedAlert{}, alert_params)

      user =
        :user
        |> build(vacation_start: nil, vacation_end: nil)
        |> PaperTrail.insert!

      create_changeset = Subscription.create_changeset(
        %Subscription{},
        params_for(:subscription, user: user, relevant_days: [:sunday], type: :bus)
      )
      PaperTrail.insert!(create_changeset)

      params = %{
        "alert_date" => %{
          "year" => "2020",
          "month" => "01",
          "day" => "01",
          "hour" => "1",
          "minute" => "1"
        },
        "alert_id" => alert.alert_id
      }

      {:ok, [result]} = Diagnostic.diagnose_alert(user, params)
      assert result.passes_vacation_period? == true
    end

    test "alert did not match do not disturb" do
      saturday_morning = 1504972475
      saturday_afternoon = 1504983275
      data = Map.put(@alert_params, "active_period", [%{
         "start" => saturday_morning,
         "end" => saturday_afternoon
       }])

      alert_params =  %{
        alert_id: "114167",
        last_modified: DateTime.from_unix!(@lpn_unix),
        data: data
      }

      alert = SavedAlert.save_new_alert(%SavedAlert{}, alert_params)

      user =
        :user
        |> build(do_not_disturb_start: nil, vacation_end: nil)
        |> PaperTrail.insert!

      create_changeset = Subscription.create_changeset(
        %Subscription{},
        params_for(:subscription, user: user, relevant_days: [:sunday], type: :bus)
      )
      PaperTrail.insert!(create_changeset)

      params = %{
        "alert_date" => %{
          "year" => "2020",
          "month" => "01",
          "day" => "01",
          "hour" => "1",
          "minute" => "1"
        },
        "alert_id" => alert.alert_id
      }

      {:ok, [result]} = Diagnostic.diagnose_alert(user, params)
      assert result.passes_do_not_disturb? == true
    end

    test "with no valid id", %{user: user} do
      params = %{
        "alert_date" => %{
          "year" => "2020",
          "month" => "01",
          "day" => "01",
          "hour" => "1",
          "minute" => "1"
        },
        "alert_id" => "1111111"
      }

      assert Diagnostic.diagnose_alert(user, params) == {:error, user}
    end

    test "with no versions (old datetime)", %{user: user, alert: alert} do
      params = %{
        "alert_date" => %{
          "year" => "2000",
          "month" => "01",
          "day" => "01",
          "hour" => "1",
          "minute" => "1"
        },
        "alert_id" => alert.alert_id
      }

      assert Diagnostic.diagnose_alert(user, params) == {:error, user}
    end
  end

  describe "diagnose_alert/2 informed entities" do
    test "alert matched informed entities", %{user: user, alert: alert} do
      params = %{
        "alert_date" => %{
          "year" => "2020",
          "month" => "01",
          "day" => "01",
          "hour" => "1",
          "minute" => "1"
        },
        "alert_id" => alert.alert_id
      }

      {:ok, [result]} = Diagnostic.diagnose_alert(user, params)

      assert result.passed_informed_entity_filter? == false
    end

    test "breaks out detailed matches", %{alert: alert} do
      user =
      :user
      |> build()
      |> PaperTrail.insert!

      sub_params = params_for(
        :subscription,
        user: user,
        relevant_days: [:sunday],
        alert_priority_type: :high,
        type: :ferry
      )
      create_changeset = Subscription.create_changeset(%Subscription{}, sub_params)
      PaperTrail.insert!(create_changeset)

      params = %{
        "alert_date" => %{
          "year" => "2020",
          "month" => "01",
          "day" => "01",
          "hour" => "1",
          "minute" => "1"
        },
        "alert_id" => alert.alert_id
      }

      {:ok, [result]} = Diagnostic.diagnose_alert(user, params)

      assert result.matches_any_route_type? == false
      assert result.matches_any_route? == false
      assert result.matches_any_direction? == false
      assert result.matches_any_facility? == false
      assert result.matches_any_stop? == false
      assert result.matches_any_trip? == false
    end
  end
end
