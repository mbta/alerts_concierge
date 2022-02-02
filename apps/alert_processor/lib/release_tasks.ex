defmodule AlertProcessor.ReleaseTasks do
  @moduledoc "Tasks that need to be available in a release"

  alias AlertProcessor.Repo
  alias Ecto.Migrator

  @start_apps [
    :crypto,
    :ssl,
    :postgrex,
    :ecto
  ]

  def migrate do
    Enum.each(@start_apps, &Application.ensure_all_started/1)
    Migrator.run(Repo, :up, all: true)
  end
end

defmodule AlertProcessor.ReleaseTasks.Dev do
  @moduledoc """
  Tasks that need to be available in a dev release
  """
  def migrate, do: nil
end
