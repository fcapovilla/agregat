defmodule AgregatWeb.ItemsLive do
  use Phoenix.LiveView

  import Ecto.Query, only: [from: 2]

  alias Agregat.Feeds

  def render(assigns) do
    AgregatWeb.LiveView.render("items.html", assigns)
  end

  def mount(%{selected: "folder-" <> folder_id}, socket) do
    items =
      (from i in Agregat.Feeds.Item,
            join: f in assoc(i, :feed),
            where: f.folder_id == ^folder_id,
            limit: 100,
            preload: [:medias, :feed])
      |> Agregat.Repo.all()
    {:ok, assign(socket, items: items, selected: nil)}
  end

  def mount(%{selected: "feed-" <> feed_id}, socket) do
    items =
      (from i in Agregat.Feeds.Item,
            where: i.feed_id == ^feed_id,
            limit: 100,
            preload: [:medias, :feed])
      |> Agregat.Repo.all()
    {:ok, assign(socket, items: items, selected: nil)}
  end

  def mount(%{selected: "all"}, socket) do
    items =
      (from i in Agregat.Feeds.Item,
            limit: 100,
            preload: [:medias, :feed])
      |> Agregat.Repo.all()
    {:ok, assign(socket, items: items, selected: nil)}
  end

  def handle_event("open-item-" <> item_id, _, socket) do
    item_id = String.to_integer(item_id)
    if socket.assigns.selected == item_id do
      {:noreply, assign(socket, selected: nil)}
    else
      {:noreply, assign(socket, selected: item_id)}
    end
  end

  def handle_event("keydown", %{"key" => "j"}, %{assigns: %{selected: selected, items: items}} = socket) do
    position = Enum.find_index(items, &(&1.id == selected))
    cond do
      position == nil -> {:noreply, assign(socket, selected: Enum.at(items, 0).id)}
      position + 1 > Enum.count(items) -> {:noreply, socket}
      true -> {:noreply, assign(socket, selected: Enum.at(items, position + 1).id)}
    end
  end

  def handle_event("keydown", %{"key" => "k"}, %{assigns: %{selected: selected, items: items}} = socket) do
    position = Enum.find_index(items, &(&1.id == selected))
    cond do
      position == nil -> {:noreply, assign(socket, selected: Enum.at(items, 0).id)}
      position < 1 -> {:noreply, socket}
      true -> {:noreply, assign(socket, selected: Enum.at(items, position - 1).id)}
    end
  end

  def handle_event("keydown", _, socket) do
    {:noreply, socket}
  end
end
