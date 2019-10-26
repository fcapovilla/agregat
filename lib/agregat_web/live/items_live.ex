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
    {:ok, assign(socket, items: items, selected: nil, ids: Enum.map(items, &(&1.id))), temporary_assigns: [:items]}
  end

  def mount(%{selected: "feed-" <> feed_id}, socket) do
    items =
      (from i in Agregat.Feeds.Item,
            where: i.feed_id == ^feed_id,
            limit: 100,
            preload: [:medias, :feed])
      |> Agregat.Repo.all()
    {:ok, assign(socket, items: items, selected: nil, ids: Enum.map(items, &(&1.id))), temporary_assigns: [:items]}
  end

  def mount(%{selected: "all"}, socket) do
    items =
      (from i in Agregat.Feeds.Item,
            limit: 100,
            preload: [:medias, :feed])
      |> Agregat.Repo.all()
    {:ok, assign(socket, items: items, selected: nil, ids: Enum.map(items, &(&1.id))), temporary_assigns: [:items]}
  end

  def handle_event("open-item-" <> item_id, _, %{assigns: %{selected: selected}} = socket) do
    item_id = String.to_integer(item_id)
    if selected != nil and selected.id == item_id do
      {:noreply, assign(socket, items: [selected], selected: nil)}
    else
      item = Agregat.Feeds.get_item!(item_id)
      if selected != nil do
        {:noreply, assign(socket, items: [selected, item], selected: item)}
      else
        {:noreply, assign(socket, items: [item], selected: item)}
      end
    end
  end

  def handle_event("keydown", %{"key" => "j"}, %{assigns: %{ids: ids, selected: selected}} = socket) do
    position = if selected != nil, do: Enum.find_index(ids, &(&1 == selected.id)), else: nil
    cond do
      position == nil ->
        item = Agregat.Feeds.get_item!(Enum.at(ids, 0))
        {:noreply, assign(socket, items: [item], selected: item)}
      position + 1 >= Enum.count(ids) ->
        {:noreply, socket}
      true ->
        item = Agregat.Feeds.get_item!(Enum.at(ids, position + 1))
        {:noreply, assign(socket, items: [selected, item], selected: item)}
    end
  end

  def handle_event("keydown", %{"key" => "k"}, %{assigns: %{ids: ids, selected: selected}} = socket) do
    position = if selected != nil, do: Enum.find_index(ids, &(&1 == selected.id)), else: nil
    cond do
      position == nil ->
        item = Agregat.Feeds.get_item!(Enum.at(ids, 0))
        {:noreply, assign(socket, items: [item], selected: item)}
      position < 1 ->
        {:noreply, socket}
      true ->
        item = Agregat.Feeds.get_item!(Enum.at(ids, position - 1))
        {:noreply, assign(socket, items: [selected, item], selected: item)}
    end
  end

  def handle_event("keydown", _, socket) do
    {:noreply, socket}
  end
end
