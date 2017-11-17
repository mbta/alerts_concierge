defmodule ConciergeSite.Dissemination.NullAdapter do
  @behaviour Bamboo.Adapter

  def deliver(email, config), do: %{email: email, config: config}

  def handle_config(config), do: config
end
