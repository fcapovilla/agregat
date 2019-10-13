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

  def handle_event("keydown", %{"key" => "j"}, socket) do
    selected = socket.assigns.selected
    position = Enum.find_index(socket.assigns.items, &(&1.id == selected))
    if position + 1 > Enum.count(socket.assigns.items) do
      {:noreply, socket}
    else
      item = Enum.at(socket.assigns.items, position + 1)
      {:noreply, assign(socket, selected: item.id)}
    end
  end

  def handle_event("keydown", %{"key" => "k"}, socket) do
    selected = socket.assigns.selected
    position = Enum.find_index(socket.assigns.items, &(&1.id == selected))
    if position < 1 do
      {:noreply, socket}
    else
      item = Enum.at(socket.assigns.items, position - 1)
      {:noreply, assign(socket, selected: item.id)}
    end
  end
end
