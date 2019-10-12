defmodule Agregat.Repo do
  use Ecto.Repo,
    otp_app: :agregat,
    adapter: Ecto.Adapters.Postgres
end
