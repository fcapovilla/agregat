defmodule Agregat.Repo.Migrations.AddUserLocale do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :locale, :string, null: false, default: "en", size: 8
    end
  end
end
