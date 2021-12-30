defmodule Agregat.Repo.Migrations.AddIndexes do
  use Ecto.Migration

  def change do
    create index(:items, [:read])
    create index(:items, [:favorite])
  end
end
