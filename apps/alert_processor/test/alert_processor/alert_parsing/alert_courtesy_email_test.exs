defmodule AlertProcessor.AlertCourtesyEmailTest do
  use ExUnit.Case, async: true
  alias AlertProcessor.AlertCourtesyEmail
  alias AlertProcessor.Model.{SavedAlert, Alert}

  @alert %Alert{
    last_push_notification: DateTime.from_naive!(~N[2018-01-01 09:30:00.000], "Etc/UTC"),
    header: "recent",
    id: "123"
  }

  @saved_alert %SavedAlert{
    alert_id: "123"
  }

  test "sends courtesy email" do
    assert [%{}] == AlertCourtesyEmail.send_courtesy_emails([@saved_alert], [@alert])
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
