defmodule Agregat.Feeds.Folder do
  use Ecto.Schema
  import Ecto.Changeset

  schema "folders" do
    field :open, :boolean, default: true
    field :position, :integer
    field :title, :string
    field :unread_count, :integer, virtual: true, default: 0
    belongs_to :user, Agregat.Users.User
    has_many :feeds, Agregat.Feeds.Feed

    timestamps()
  end

  @doc false
  def changeset(folder, attrs) do
    folder
    |> cast(attrs, [:title, :open, :position, :user_id])
    |> validate_required([:title, :open])
  end
end
