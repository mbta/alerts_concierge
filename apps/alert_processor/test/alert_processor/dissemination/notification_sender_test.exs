defmodule AlertProcessor.Dissemination.NotificationSenderTest do
  @moduledoc false
  use ExUnit.Case

  alias AlertProcessor.Model.Notification
  alias AlertProcessor.Dissemination.NotificationSender

  describe "email/1" do
    test "sends an email using the configured email builder and mailer" do
      notification = %Notification{email: "test@example.com", header: "This is a test"}

      {:ok, _} = NotificationSender.email(notification)

      assert_receive {:sent_email, %{to: "test@example.com", notification: ^notification}}
    end

    test "catches the configured email exception and converts it to an error return" do
      notification = %Notification{email: "raise_error@example.com", header: "This is a test"}

      assert {:error, %{message: "error requested"}} = NotificationSender.email(notification)
    end
  end

  describe "sms/1" do
    test "sends an SMS with the alert header" do
      notification = %Notification{
        header: "This is a test",
        phone_number: "5555551234",
        type: :initial
      }

      {:ok, _} = NotificationSender.sms(notification)

      assert_receive {:publish, %{"Message" => "This is a test", "PhoneNumber" => "+15555551234"}}
    end

    test "formats an all-clear notification" do
      notification = %Notification{
        header: "This is a test",
        phone_number: "5555551234",
        type: :all_clear
      }

      {:ok, _} = NotificationSender.sms(notification)

      assert_receive {:publish, %{"Message" => "All clear (re: This is a test)"}}
    end

    test "formats a reminder notification" do
      notification = %Notification{
        header: "This is a test",
        phone_number: "5555551234",
        type: :reminder
      }

      {:ok, _} = NotificationSender.sms(notification)

      assert_receive {:publish, %{"Message" => "Reminder: This is a test"}}
    end

    test "formats an update notification" do
      notification = %Notification{
        header: "This is a test",
        phone_number: "5555551234",
        type: :update
      }

      {:ok, _} = NotificationSender.sms(notification)

      assert_receive {:publish, %{"Message" => "Update: This is a test"}}
    end
  end
end
