defmodule Agregat.Feeds.Media do
  use Ecto.Schema
  import Ecto.Changeset

  schema "medias" do
    field :type, :string
    field :url, :string
    belongs_to :item, Agregat.Feeds.Item

    timestamps()
  end

  @doc false
  def changeset(media, attrs) do
    media
    |> cast(attrs, [:type, :url, :item_id])
    |> validate_required([:type, :url])
  end
end
