defmodule Agregat.Feeds.Item do
  use Ecto.Schema
  import Ecto.Changeset

  schema "items" do
    field :content, :string
    field :date, :naive_datetime
    field :favorite, :boolean, default: false
    field :guid, :string
    field :orig_feed_title, :string
    field :read, :boolean, default: false
    field :title, :string
    field :url, :string
    field :user_id, :id
    field :feed_id, :id

    timestamps()
  end

  @doc false
  def changeset(item, attrs) do
    item
    |> cast(attrs, [:title, :url, :guid, :content, :read, :favorite, :date, :orig_feed_title])
    |> validate_required([:title, :url, :guid, :content, :read, :favorite, :date, :orig_feed_title])
  end
end
