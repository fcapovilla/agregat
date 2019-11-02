# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :agregat,
  ecto_repos: [Agregat.Repo]

# Configures the endpoint
config :agregat, AgregatWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "HZmrk2nnUX3HywwkmFQbO+zsFs9EKDbVVc5Ynhk6Xm84CqyshSoX+we7VIeIiwlB",
  render_errors: [view: AgregatWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Agregat.PubSub, adapter: Phoenix.PubSub.PG2],
  live_view: [signing_salt: "UQAdDQFE1E+7rfqEGYWprRk6HRXdF/HX"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"

config :agregat, :pow,
  user: Agregat.Users.User,
  repo: Agregat.Repo,
  web_module: AgregatWeb

# Quantum scheduled tasks
config :agregat, Agregat.Scheduler, jobs: [
  sync: [
    schedule: "*/10 * * * *",
    task: {Agregat.Syncer, :sync_all, []},
    overlap: false
  ],
  recalculate_sync_frequency: [
    schedule: "0 1 * * *",
    task: {Agregat.Syncer, :recalculate_sync_frequencies, []},
    overlap: false
  ],
]
