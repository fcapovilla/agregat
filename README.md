# Agregat

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.setup`
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`
  
To start in Docker:

  * Go in the `release` directory.
  * Update the `docker-compose.yml` to set the `SECRET_KEY_BASE` and `HOST` environment variables.
  * Run `docker-compose up`.

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Deploying on CapRover

* Use CapRover's One-Click App tools to create a PostgreSQL app.
* Create an empty app for Agregat.
* Look at the default environment variables in the `captain-definition` file and add overrides them if necessary. You must set the `SECRET_KEY_BASE` and `HOST` variables.
* Deploy the app by running `caprover deploy` and select the empty app you created previously.

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix
