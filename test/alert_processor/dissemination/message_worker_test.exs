defmodule MbtaServer.AlertProcessor.MessageWorkerTest do
  use MbtaServer.Web.ConnCase, async: false
  use Bamboo.Test, shared: true

  alias MbtaServer.AlertMessageMailer
  alias MbtaServer.AlertProcessor.{SendingQueue, Model.AlertMessage}

  setup do
    Application.stop(:mbta_server)
    on_exit(self(), fn() -> Application.start(:mbta_server) end)

    email = "test@example.com"
    body = "This is a test alert"
    body_2 = "Another alert"
    phone_number = "+15555551234"

    message = %AlertMessage{
      message: body,
      email: email,
      phone_number: phone_number,
      send_after: DateTime.utc_now()
    }

    message_2 = %AlertMessage{
      message: body_2,
      email: email,
      phone_number: phone_number,
      send_after: DateTime.utc_now()
    }

    {:ok, message: message, message_2: message_2, email: email, body: body, body_2: body_2}
  end

  test "Worker passes jobs from sending queue to messager", %{message: message, body: body, email: email} do
    MbtaServer.AlertProcessor.start_link()
    SendingQueue.enqueue(message)

    assert_delivered_email AlertMessageMailer.alert_message_email(body, email)
  end

  test "Worker runs on interval jobs from sending queue to messager", %{message: message, message_2: message_2, body: body, body_2: body_2, email: email} do
    MbtaServer.AlertProcessor.start_link()
    SendingQueue.enqueue(message)

    assert_delivered_email AlertMessageMailer.alert_message_email(body, email)
    assert SendingQueue.pop == {:error, :empty}

    SendingQueue.enqueue(message_2)
    :timer.sleep(101)

    assert_delivered_email AlertMessageMailer.alert_message_email(body_2, email)
  end
end
