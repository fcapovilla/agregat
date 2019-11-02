defmodule Agregat.Users.User do
  use Ecto.Schema
  use Pow.Ecto.Schema

  schema "users" do
    field :admin, :boolean, default: false

    pow_user_fields()

    timestamps()
  end

  def changeset(user_or_changeset, attrs) do
    user_or_changeset
    |> pow_changeset(attrs)
    |> Ecto.Changeset.cast(attrs, [:admin])
  end
end
