defmodule MbtaServer.Repo.Migrations.RenameFacilityInInformedEntities do
  use Ecto.Migration

  def change do
    rename table(:informed_entities), :facility, to: :facility_type
  end
end
