defmodule Agregat.Feeds.Favicon do
  use Ecto.Schema
  import Ecto.Changeset

  schema "favicons" do
    field :data, :string
    field :host, :string

    timestamps()
  end

  @doc false
  def changeset(favicon, attrs) do
    favicon
    |> cast(attrs, [:host, :data])
    |> validate_required([:host, :data])
  end
end
