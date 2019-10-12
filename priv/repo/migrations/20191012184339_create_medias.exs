defmodule Agregat.Repo.Migrations.CreateMedias do
  use Ecto.Migration

  def change do
    create table(:medias) do
      add :type, :string
      add :url, :string
      add :item_id, references(:items, on_delete: :delete_all)

      timestamps()
    end

    create index(:medias, [:item_id])
  end
end
