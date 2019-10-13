defmodule AgregatWeb.ItemsLive do
  use Phoenix.LiveView

  import Ecto.Query, only: [from: 2]

  alias Agregat.Feeds

  def render(assigns) do
    AgregatWeb.LiveView.render("items.html", assigns)
  end

  def mount(%{folder_id: folder_id}, socket) do
    items =
      (from i in Agregat.Feeds.Item,
            join: f in assoc(i, :feed),
            where: f.folder_id == ^folder_id,
            limit: 100,
            preload: [:medias, :feed])
      |> Agregat.Repo.all()
    {:ok, assign(socket, items: items, selected: nil)}
  end

  def mount(%{feed_id: feed_id}, socket) do
    items =
      (from i in Agregat.Feeds.Item,
            where: i.feed_id == ^feed_id,
            limit: 100,
            preload: [:medias, :feed])
      |> Agregat.Repo.all()
    {:ok, assign(socket, items: items, selected: nil)}
  end

  def mount(%{}, socket) do
    items =
      (from i in Agregat.Feeds.Item,
            limit: 100,
            preload: [:medias, :feed])
      |> Agregat.Repo.all()
    {:ok, assign(socket, items: items, selected: nil)}
  end

  def handle_event("open-item-" <> item_id, _, socket) do
    item_id = String.to_integer(item_id)
    {:noreply, assign(socket, selected: item_id)}
  end
end
