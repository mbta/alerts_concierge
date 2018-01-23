defmodule AlertProcessor.NotificationWorkerTest do
  use AlertProcessor.DataCase
  use Bamboo.Test, shared: true
  import ExUnit.CaptureLog

  alias AlertProcessor.{Model, NotificationWorker, RateLimiter, SendingQueue}
  alias Model.{Alert, InformedEntity, Notification}
  import AlertProcessor.Factory

  @alert %Alert{
    id: "1",
    informed_entities: [
      %InformedEntity{route: "Blue", route_type: 1}
    ]
  }

  setup_all do
    email = "test@example.com"
    body = "This is a test alert"
    body_2 = "Another alert"
    effect = "effect"
    status = "unsent"

    notification = %Notification{
      header: body,
      service_effect: effect,
      alert_id: "1",
      email: email,
      phone_number: nil,
      send_after: DateTime.utc_now(),
      status: status,
      alert: @alert
    }

    notification_2 = %Notification{
      header: body_2,
      service_effect: effect,
      alert_id: "1",
      email: email,
      phone_number: nil,
      send_after: DateTime.utc_now(),
      status: status,
      alert: @alert
    }

    notification_3 = %Notification{
      header: body,
      service_effect: effect,
      alert_id: "1",
      email: email,
      phone_number: nil,
      send_after: DateTime.utc_now(),
      status: status,
      alert: @alert
    }

    {:ok, notification: notification, notification_2: notification_2, notification_3: notification_3}
  end

  test "Worker passes jobs from sending queue to notification", %{notification: notification} do
    user = insert :user
    notification = Map.put(notification, :user, user)

    SendingQueue.start_link()
    {:ok, pid} = NotificationWorker.start_link([name: :notification_worker_test])
    :erlang.trace(pid, true, [:receive])

    SendingQueue.enqueue(notification)
    :timer.sleep(101)

    assert_receive {:trace, ^pid, :receive, {:sent_notification_email, _}}
    assert_number_of_notifications_persisted_for_user(1, user)
  end

  test "Does not exceed rate limit", %{notification: notification} do
    user = insert :user
    notification = Map.put(notification, :user, user)

    old_config = Application.get_all_env(:alert_processor)
    on_exit fn ->
      for {k, v} <- old_config, do: Application.put_env(:alert_processor, k, v)
    end
    Application.put_env(:alert_processor, :rate_limit_scale, "1000000")
    Application.put_env(:alert_processor, :rate_limit, "1")

    RateLimiter.check_rate_limit(user.id)

    SendingQueue.start_link()
    {:ok, pid} = NotificationWorker.start_link([name: :notification_worker_test])
    :erlang.trace(pid, true, [:receive])

    a = fn ->
      SendingQueue.enqueue(notification)
      :timer.sleep(101)

      assert_number_of_notifications_persisted_for_user(0, user)
    end

    assert capture_log(a) =~ "Sending rate exceeded for user: #{user.id}"
  end

  test "Notification is invalid", %{notification: notification} do
    user = insert :user
    notification = Map.put(notification, :user, user)
    notification = Map.put(notification, :service_effect, nil)

    SendingQueue.start_link()
    {:ok, pid} = NotificationWorker.start_link([name: :notification_worker_test])
    :erlang.trace(pid, true, [:receive])

    SendingQueue.enqueue(notification)
    :timer.sleep(101)

    refute_receive {:trace, ^pid, :receive, {:sent_notification_email, _}}
    assert_number_of_notifications_persisted_for_user(0, user)
  end

  defp assert_number_of_notifications_persisted_for_user(count, user) do
    assert count == Repo.one(from n in Notification, where: n.user_id == ^user.id, select: count(n.id))
  end
end
