defmodule Agregat.Feeds.Feed do
  use Ecto.Schema
  import Ecto.Changeset

  schema "feeds" do
    field :auto_frequency, :boolean, default: false
    field :last_sync, :utc_datetime
    field :position, :integer
    field :sync_status, :string
    field :title, :string
    field :unread_count, :integer
    field :update_frequency, :integer
    field :url, :string
    belongs_to :user, Agregat.Accounts.User
    belongs_to :folder, Agregat.Feeds.Folder
    belongs_to :favicon, Agregat.Feeds.Favicon
    has_many :items, Agregat.Feeds.Item

    timestamps()
  end

  @doc false
  def changeset(feed, attrs) do
    feed
    |> cast(attrs, [:title, :url, :last_sync, :unread_count, :sync_status, :position, :update_frequency, :auto_frequency])
    |> validate_required([:url])
  end
end
