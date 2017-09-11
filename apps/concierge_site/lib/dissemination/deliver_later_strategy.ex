defmodule ConciergeSite.Dissemination.DeliverLaterStrategy do
  @behaviour Bamboo.DeliverLaterStrategy
  require Logger

  def deliver_later(adapter, email, config) do
    Task.async(fn ->
      result = adapter.deliver(email, config)
      Logger.info(inspect(result))
      result
    end)
  end
end
