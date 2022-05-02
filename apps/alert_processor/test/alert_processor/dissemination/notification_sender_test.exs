defmodule AlertProcessor.Dissemination.NotificationSenderTest do
  @moduledoc false
  use ExUnit.Case

  alias AlertProcessor.Dissemination.NotificationSender
  alias AlertProcessor.Model.Notification

  describe "email sending" do
    test "sends an email using the configured email builder and mailer" do
      notification = %Notification{email: "test@example.com", header: "This is a test"}

      {:ok, _} = NotificationSender.send(notification)

      assert_receive {:sent_email, %{to: "test@example.com", notification: ^notification}}
      refute_receive {:publish, _}
    end

    test "returns an error from the mailer" do
      notification = %Notification{email: "mailer_error@example.com", header: "This is a test"}

      assert {:error, %{message: "error requested"}} = NotificationSender.send(notification)
    end
  end

  describe "SMS sending" do
    test "sends an SMS with the alert header" do
      notification = %Notification{
        header: "This is a test",
        phone_number: "5555551234",
        type: :initial
      }

      {:ok, _} = NotificationSender.send(notification)

      assert_receive {:publish, %{"Message" => "This is a test", "PhoneNumber" => "+15555551234"}}
    end

    test "sends SMS and not email when both are possible" do
      notification = %Notification{
        email: "test@example.com",
        header: "This is a test",
        phone_number: "5555551234",
        type: :initial
      }

      {:ok, _} = NotificationSender.send(notification)

      assert_received {:publish, _}
      refute_received {:sent_email, _}
    end

    test "formats an all-clear notification" do
      notification = %Notification{
        header: "This is a test",
        phone_number: "5555551234",
        type: :all_clear
      }

      {:ok, _} = NotificationSender.send(notification)

      assert_receive {:publish, %{"Message" => "All clear (re: This is a test)"}}
    end

    test "formats a reminder notification" do
      notification = %Notification{
        header: "This is a test",
        phone_number: "5555551234",
        type: :reminder
      }

      {:ok, _} = NotificationSender.send(notification)

      assert_receive {:publish, %{"Message" => "Reminder: This is a test"}}
    end

    test "formats an update notification" do
      notification = %Notification{
        header: "This is a test",
        phone_number: "5555551234",
        type: :update
      }

      {:ok, _} = NotificationSender.send(notification)

      assert_receive {:publish, %{"Message" => "Update: This is a test"}}
    end
  end
end
