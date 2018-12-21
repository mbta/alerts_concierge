defmodule AlertProcessor.NotificationWindowFilterMock do
  @moduledoc false

  def filter(subscriptions, _alert, _now), do: subscriptions
end
