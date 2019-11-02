defmodule Agregat.Users.User do
  use Ecto.Schema
  use Pow.Ecto.Schema

  schema "users" do
    field :admin, :boolean, default: false

    pow_user_fields()

    timestamps()
  end

  def changeset(user, attrs) do
    user
    |> pow_changeset(attrs)
    |> Ecto.Changeset.cast(attrs, [:admin])
  end

  def admin_changeset(user, attrs) do
    user
    |> pow_user_id_field_changeset(attrs)
    |> maybe_new_password(attrs)
    |> Ecto.Changeset.cast(attrs, [:admin])
  end

  defp maybe_new_password(changeset, attrs) do
    case password_changed?(attrs) do
      true  -> pow_password_changeset(changeset, attrs)
      false -> changeset
    end
  end

  defp password_changed?(params), do: Map.get(params, "password", "") != ""
end
