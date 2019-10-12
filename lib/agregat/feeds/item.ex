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
    belongs_to :user, Agregat.Accounts.User
    belongs_to :feed, Agregat.Feeds.Feed
    has_many :medias, Agregat.Feeds.Media, on_replace: :delete

    timestamps()
  end

  @doc false
  def changeset(item, attrs) do
    item
    |> cast(attrs, [:title, :url, :guid, :content, :read, :favorite, :date, :orig_feed_title])
    |> validate_required([:title, :url, :guid, :content, :read, :favorite, :date, :orig_feed_title])
  end
end
