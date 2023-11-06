defmodule AlertProcessor.NotificationBuilder do
  @moduledoc """
  Responsible for construction of Notifications from an Alert and Subscription
  """

  require Logger
  alias AlertProcessor.Model.{Notification, User}

  def build_notification({user, subscriptions}, alert) do
    %{phone_number: phone_number, email: email} = phone_number_or_email(user)

    %Notification{
      alert_id: alert.id,
      user: user,
      user_id: user.id,
      header: alert.header,
      service_effect: alert.service_effect,
      description: alert.description,
      url: alert.url,
      phone_number: phone_number,
      email: email,
      status: :unsent,
      last_push_notification: alert.last_push_notification,
      alert: alert,
      notification_subscriptions:
        Enum.map(
          subscriptions,
          &%AlertProcessor.Model.NotificationSubscription{subscription_id: &1.id}
        ),
      closed_timestamp: alert.closed_timestamp,
      type: List.first(subscriptions).notification_type_to_send || :initial,
      image_url: alert.image_url,
      image_alternative_text: alert.image_alternative_text
    }
  end

  @spec phone_number_or_email(User.t()) :: %{
          phone_number: String.t() | nil,
          email: String.t() | nil
        }
  defp phone_number_or_email(%User{communication_mode: "sms", phone_number: phone_number})
       when not is_nil(phone_number) do
    %{
      phone_number: phone_number,
      email: nil
    }
  end

  defp phone_number_or_email(%User{email: email}) do
    %{
      phone_number: nil,
      email: email
    }
  end
end
