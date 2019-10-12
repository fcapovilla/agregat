defmodule Agregat.Feeds.Folder do
  use Ecto.Schema
  import Ecto.Changeset

  schema "folders" do
    field :open, :boolean, default: false
    field :position, :integer
    field :title, :string
    field :user_id, :id

    timestamps()
  end

  @doc false
  def changeset(folder, attrs) do
    folder
    |> cast(attrs, [:title, :open, :position])
    |> validate_required([:title, :open, :position])
  end
end
