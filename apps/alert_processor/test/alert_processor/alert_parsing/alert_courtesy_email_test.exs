defmodule AlertProcessor.AlertCourtesyEmailTest do
  @moduledoc false
  use ExUnit.Case, async: true
  alias AlertProcessor.AlertCourtesyEmail
  alias AlertProcessor.Model.{SavedAlert, Alert}

  @alert %Alert{
    last_push_notification: DateTime.from_naive!(~N[2018-01-01 09:30:00.000], "Etc/UTC"),
    header: "recent",
    id: "123"
  }

  @saved_alert %SavedAlert{
    alert_id: "123",
    notification_type: :initial
  }

  test "send initial courtesy email" do
    assert [notification] = AlertCourtesyEmail.send_courtesy_emails([@saved_alert], [@alert])
    assert notification.type == :initial
  end

  test "send update courtesy email" do
    assert [notification] =
             AlertCourtesyEmail.send_courtesy_emails(
               [%{@saved_alert | notification_type: :update}],
               [@alert]
             )

    assert notification.type == :update
  end

  test "send all clear courtesy email" do
    assert [notification] =
             AlertCourtesyEmail.send_courtesy_emails([@saved_alert], [
               %{
                 @alert
                 | closed_timestamp: DateTime.from_naive!(~N[2018-01-01 09:30:00.000], "Etc/UTC"),
                   last_push_notification:
                     DateTime.from_naive!(~N[2018-01-01 09:30:00.000], "Etc/UTC")
               }
             ])

    assert notification.type == :all_clear
  end

  test "do not send all clear courtesy email when closed_timestamp does not match last_push_notification" do
    assert [] =
             AlertCourtesyEmail.send_courtesy_emails([@saved_alert], [
               %{
                 @alert
                 | closed_timestamp: DateTime.from_naive!(~N[2018-01-01 09:30:00.000], "Etc/UTC"),
                   last_push_notification:
                     DateTime.from_naive!(~N[2017-01-01 09:30:00.000], "Etc/UTC")
               }
             ])
  end

  test "does not send courtesy email when ids do not match" do
    saved_alert = %SavedAlert{@saved_alert | alert_id: "456"}
    assert [] == AlertCourtesyEmail.send_courtesy_emails([saved_alert], [@alert])
  end

  test "does not send courtesy email when saved_alerts is empty" do
    assert [] == AlertCourtesyEmail.send_courtesy_emails([], [@alert])
  end

  test "does not send courtesy email when alerts is empty" do
    assert [] == AlertCourtesyEmail.send_courtesy_emails([@saved_alert], [])
  end
end
