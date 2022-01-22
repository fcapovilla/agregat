defmodule Agregat.Repo.Migrations.AddItemIndexes do
  use Ecto.Migration

  def change do
    create index(:items, [:date], where: "read = false", name: "items_date_unread_index")
  end
end
