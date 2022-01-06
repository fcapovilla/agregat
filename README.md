# Agregat

A small RSS Reader using Phoenix LiveView and Alpine.js

## Run locally

Requirements:

* Erlang 24
* Elixir 1.12
* Postgresql 2.6

To install all language dependencies with [ASFD](https://asdf-vm.com/), simply run `asdf install` from this directory.

To start your Phoenix server in development mode:

  * A running Postgresql server is required. You can start one with docker by running `docker-compose up` from this directory.
  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.setup`
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

The default admin user is `admin@example.com` with the password `password`.

## Deploying with Docker

To start in production mode with Docker:

  * Go in the `release` directory.
  * Update the `docker-compose.yml` to set the `SECRET_KEY_BASE` and `HOST` environment variables.
    * You can generate a key with the `mix phx.gen.secret` command.
  * Run `docker-compose up`.

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser and connect with the `admin@example.com` user.

## Deploying with CapRover

To deploy this app in production mode on a CapRover instance:

* Use CapRover's One-Click App tools to create a PostgreSQL app.
* Create an empty app for Agregat.
* Look at the default environment variables in the `captain-definition` file and add overrides them if necessary. You must set the `SECRET_KEY_BASE` and `HOST` variables.
* Deploy the app by running `caprover deploy` and select the empty app you created previously.

## Pushing Docker images

To build and push a new docker image:

* Connect to Github Container Registry with `docker login ghcr.io -u USERNAME -p TOKEN'`
* Run `release/push.sh` to push a new image with the `latest` tag.
* Run `release/push.sh TAG` to push an image with a specific tag.

## References

* Phoenix Framework: https://www.phoenixframework.org/
* Phoenix LiveView: https://hexdocs.pm/phoenix_live_view/
* Alpine.js: https://alpinejs.dev/
* Milligram: https://milligram.io/
* FontAwesome: https://fontawesome.com/
* CapRover: https://caprover.com/
