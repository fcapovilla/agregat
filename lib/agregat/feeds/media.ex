defmodule Agregat.Feeds.Media do
  use Ecto.Schema
  import Ecto.Changeset

  schema "medias" do
    field :type, :string
    field :url, :string
    field :item_id, :id

    timestamps()
  end

  @doc false
  def changeset(media, attrs) do
    media
    |> cast(attrs, [:type, :url])
    |> validate_required([:type, :url])
  end
end
