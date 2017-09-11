defmodule ConciergeSite.Dissemination.DeliverLaterStrategy do
  @behaviour Bamboo.DeliverLaterStrategy
  require Logger

  def deliver_later(adapter, email, config) do
    Task.async(fn ->
      result = adapter.deliver(email, config)
      Logger.info(fn -> "Email result: #{inspect(result)}" end)
      result
    end)
  end
end
