defmodule AgregatWeb.ItemController do
  use AgregatWeb, :controller

  alias Agregat.Feeds
  alias Agregat.Feeds.Item

  def index(conn, _params) do
    conn
    |> assign(:selected, "all")
    |> Phoenix.LiveView.Controller.live_render(AgregatWeb.ItemsLive, session: %{})
  end
end
