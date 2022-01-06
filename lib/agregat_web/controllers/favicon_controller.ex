defmodule AgregatWeb.FaviconController do
  use AgregatWeb, :controller

  alias Agregat.Feeds

  def show(conn, %{"id" => id}) do
    favicon = Feeds.get_favicon!(id)

    conn
    |> put_resp_header("content-type", "image/x-icon")
    |> put_resp_header("cache-control", "public, max-age=604799")
    |> send_resp(200, Base.decode64!(favicon.data))
  end

  def refresh(conn, _params) do
    Feeds.list_favicons()
    |> Task.async_stream(&Agregat.FaviconFetcher.fetch(&1.host, true),
      max_concurrency: 5,
      timeout: 30_000
    )
    |> Enum.to_list()

    conn
    |> put_flash(:info, gettext("Favicons updated"))
    |> redirect(to: Routes.user_path(conn, :index))
  end
end
