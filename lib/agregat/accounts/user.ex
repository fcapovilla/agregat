defmodule Agregat.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :admin, :boolean, default: false
    field :hashed_password, :string
    field :username, :string
    field :password, :string, virtual: true, default: "********"

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :password, :admin])
    |> validate_required([:username, :password, :admin])
  end
end
