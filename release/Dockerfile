# ./Dockerfile

# Extend from the official Elixir image
FROM elixir:1.12.3

RUN apt-get update && \
  apt-get install -y postgresql-client && \
  curl -sL https://deb.nodesource.com/setup_10.x | bash && \
  apt-get install -y nodejs && \
  apt-get install -y build-essential

# Install hex package manager
# By using --force, we don’t need to type “Y” to confirm the installation
RUN mix local.hex --force
RUN mix local.rebar --force

ENV MIX_ENV=prod
ENV PORT=4000
ENV DATABASE_URL=postgres://postgres:postgres:@localhost/agregat
ENV SECRET_KEY_BASE=CHANGE_ME

# Create app directory and copy the Elixir projects into it
RUN mkdir /app
COPY . /app
WORKDIR /app

# Compile the project
RUN mix deps.get --only prod
RUN mix compile
RUN npm install --prefix ./assets
RUN mix phx.digest

CMD ["/app/release/entrypoint.sh"]
