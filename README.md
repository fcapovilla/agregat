# Agregat

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.setup`
  * Install Node.js dependencies with `npm install` inside the `assets` directory
  * Start Phoenix endpoint with `mix phx.server`
  
To start in Docker:

  * Go in the `release` directory.
  * Update the `docker-compose.yml` to set the `SECRET_KEY_BASE` and `HOST` environment variables.
  * Run `docker-compose up`.

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Deploying on CapRover

* Use CapRover's One-Click App tools to create a PostgreSQL app.
* Create an empty app for Agregat.
* Modify the `captain-definition file and set all environment variables using the values you entered when configuring your PostgreSQL app.
* Deploy the app by running `caprover deploy` and selecting the empty app you created previously.

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix
