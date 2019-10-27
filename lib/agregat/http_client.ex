defmodule Agregat.HttpClient do
  use Tesla

  adapter Tesla.Adapter.Hackney

  plug Tesla.Middleware.Headers, [{"user-agent", "Agregat"}]
  plug Tesla.Middleware.FollowRedirects
  plug Tesla.Middleware.Timeout, timeout: 10_000
end
