defmodule ConciergeSite.FeatureCase do
  @moduledoc """
  Setup for feature tests
  """
  use ExUnit.CaseTemplate

  using do
    quote do
      use Wallaby.Feature

      alias ConciergeSite.Repo
      alias Wallaby.Query

      import Ecto
      import Ecto.Changeset
      import Ecto.Query

      import ConciergeSite.FeatureTestHelper
      import ConciergeSite.Router.Helpers
    end
  end
end
