defmodule Agregat.Repo.Migrations.ResizeMediaUrl do
  use Ecto.Migration

  def change do
    alter table(:medias) do
      modify :url, :string, size: 2000
    end
  end
end
