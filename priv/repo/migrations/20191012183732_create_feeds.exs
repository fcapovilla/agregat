defmodule Agregat.Repo.Migrations.CreateFeeds do
  use Ecto.Migration

  def change do
    create table(:feeds) do
      add :title, :text
      add :url, :string, size: 2000
      add :last_sync, :utc_datetime, default: fragment("now()")
      add :unread_count, :integer
      add :sync_status, :text
      add :position, :integer
      add :update_frequency, :integer, default: 0
      add :auto_frequency, :boolean, default: true, null: false
      add :user_id, references(:users, on_delete: :delete_all)
      add :folder_id, references(:folders, on_delete: :delete_all)
      add :favicon_id, references(:favicons, on_delete: :nilify_all)

      timestamps()
    end

    create index(:feeds, [:user_id])
    create index(:feeds, [:folder_id])
    create index(:feeds, [:favicon_id])
  end
end
