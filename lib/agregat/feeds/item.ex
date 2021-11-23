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
    belongs_to :user, Agregat.Users.User
    belongs_to :feed, Agregat.Feeds.Feed
    has_many :medias, Agregat.Feeds.Media, on_replace: :delete

    timestamps()
  end

  @doc false
  def changeset(item, attrs) do
    item
    |> cast(attrs, [
      :title,
      :url,
      :guid,
      :content,
      :read,
      :favorite,
      :date,
      :orig_feed_title,
      :feed_id,
      :user_id
    ])
    |> cast_assoc(:medias, with: &Agregat.Feeds.Media.changeset/2)
    |> validate_required([:guid, :read, :favorite])
  end
end
