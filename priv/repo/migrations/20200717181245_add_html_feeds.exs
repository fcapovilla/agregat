defmodule Agregat.Repo.Migrations.AddHtmlFeeds do
  use Ecto.Migration

  def change do
    alter table(:feeds) do
      add :is_html, :boolean, default: false, null: false
      add :parsing_settings, :map, default: %{}
    end
  end
end
