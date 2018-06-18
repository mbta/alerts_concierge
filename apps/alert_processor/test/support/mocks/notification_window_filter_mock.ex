defmodule AlertProcessor.NotificationWindowFilterMock do
  @moduledoc false

  def filter(subscriptions, _now), do: subscriptions
end
