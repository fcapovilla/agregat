defmodule Agregat.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      Agregat.Repo,
      # Start the Telemetry supervisor
      AgregatWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Agregat.PubSub},
      # Start the Endpoint (http/https)
      AgregatWeb.Endpoint,
      # Start a worker by calling: Agregat.Worker.start_link(arg)
      # {Agregat.Worker, arg}
      Agregat.Scheduler
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Agregat.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    AgregatWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
