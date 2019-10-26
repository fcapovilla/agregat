defmodule AgregatWeb.FaviconController do
  use AgregatWeb, :controller

  alias Agregat.Feeds
  alias Agregat.Feeds.Favicon

  def show(conn, %{"id" => id}) do
    favicon = Feeds.get_favicon!(id)

    conn
    |> put_resp_header("content-type", "image/x-icon")
    |> put_resp_header("cache-control", "public, max-age=604799")
    |> send_resp(200, Base.decode64!(favicon.data))
  end
end
