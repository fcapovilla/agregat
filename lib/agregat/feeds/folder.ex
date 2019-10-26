defmodule Agregat.Feeds.Folder do
  use Ecto.Schema
  import Ecto.Changeset

  schema "folders" do
    field :open, :boolean, default: true
    field :position, :integer
    field :title, :string
    belongs_to :user, Agregat.Accounts.User
    has_many :feeds, Agregat.Feeds.Feed

    timestamps()
  end

  @doc false
  def changeset(folder, attrs) do
    folder
    |> cast(attrs, [:title, :open, :position])
    |> validate_required([:title, :open])
  end
end
