defmodule Agregat.Repo.Migrations.CreateUsersAuthTables do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    alter table(:users) do
      add :hashed_password, :string, null: false, default: Bcrypt.hash_pwd_salt("password")
      add :confirmed_at, :naive_datetime
      modify :email, :citext, null: false
      remove :password_hash
    end

    alter table(:users) do
      modify :hashed_password, :string, null: false, default: nil
    end

    create table(:users_tokens) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :token, :binary, null: false
      add :context, :string, null: false
      add :sent_to, :string

      timestamps(updated_at: false)
    end

    create index(:users_tokens, [:user_id])
    create unique_index(:users_tokens, [:context, :token])
  end
end
