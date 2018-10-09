defmodule ConciergeSite.FeatureCase do
  @moduledoc """
  Setup for feature tests
  """
  use ExUnit.CaseTemplate

  using do
    quote do
      use Wallaby.DSL

      alias ConciergeSite.Repo
      import Ecto
      import Ecto.Changeset
      import Ecto.Query

      import ConciergeSite.Router.Helpers
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(AlertProcessor.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(AlertProcessor.Repo, {:shared, self()})
    end

    metadata = Phoenix.Ecto.SQL.Sandbox.metadata_for(AlertProcessor.Repo, self())
    {:ok, session} = Wallaby.start_session(metadata: metadata)
    {:ok, session: session}
  end
end
