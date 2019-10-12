defmodule Agregat.Repo.Migrations.CreateFolders do
  use Ecto.Migration

  def change do
    create table(:folders) do
      add :title, :text
      add :open, :boolean, default: false, null: false
      add :position, :integer
      add :user_id, references(:users, on_delete: :delete_all)

      timestamps()
    end

    create index(:folders, [:user_id])
    create index(:folders, [:position])
    create unique_index(:folders, [:title, :user_id])
  end
end
