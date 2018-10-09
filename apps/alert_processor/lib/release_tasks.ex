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
    Migrator.run(Repo, migrations_path(:alert_processor), :up, all: true)
  end

  defp migrations_path(app), do: Application.app_dir(app, "priv/repo/migrations")
end

defmodule AlertProcessor.ReleaseTasks.Dev do
  @moduledoc """
  Tasks that need to be available in a dev release
  """
  def migrate, do: nil
end
