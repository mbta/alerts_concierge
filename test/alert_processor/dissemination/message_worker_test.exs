defmodule MbtaServer.AlertProcessor.MessageWorkerTest do
  use MbtaServer.Web.ConnCase
  alias MbtaServer.AlertProcessor.{SendingQueue, Model.AlertMessage}

  setup do
    message = %AlertMessage{send_after: DateTime.utc_now()}

    {:ok, message: message}
  end

  test "Worker passes jobs from sending queue to messager", %{message: message} do
    # mock messager somehow (named process?)
    # add job to sending queue
    SendingQueue.enqueue(message)
    # confirm message was received
  end
end
