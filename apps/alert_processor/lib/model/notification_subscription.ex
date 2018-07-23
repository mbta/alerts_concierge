defmodule AlertProcessor.Model.NotificationSubscription do
  use Ecto.Schema

  schema "notification_subscriptions" do
    belongs_to(:notification, AlertProcessor.Model.Notification, type: :binary_id)
    belongs_to(:subscription, AlertProcessor.Model.Subscription, type: :binary_id)

    timestamps()
  end
end
