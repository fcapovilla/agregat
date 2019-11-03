# ./Dockerfile

# Extend from the official Elixir image
FROM elixir:1.9.2

RUN apt-get update && \
  apt-get install -y postgresql-client && \
  curl -sL https://deb.nodesource.com/setup_10.x | bash && \
  apt-get install -y nodejs && \
  apt-get install -y build-essential

# Create app directory and copy the Elixir projects into it
RUN mkdir /app
COPY . /app
WORKDIR /app

# Install hex package manager
# By using --force, we don’t need to type “Y” to confirm the installation
RUN mix local.hex --force
RUN mix local.rebar --force

CMD ["/app/entrypoint.sh"]