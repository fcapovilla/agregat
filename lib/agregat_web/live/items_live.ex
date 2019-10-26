defmodule AgregatWeb.ItemsLive do
  use Phoenix.LiveView

  import Ecto.Query, only: [from: 2]

  alias Agregat.Feeds

  def render(assigns) do
    AgregatWeb.LiveView.render("items.html", assigns)
  end

  def mount(%{selected: "folder-" <> folder_id}, socket) do
    items =
      (from i in Feeds.Item,
            join: f in assoc(i, :feed),
            where: f.folder_id == ^folder_id,
            limit: 100,
            preload: [:medias, :feed])
      |> Agregat.Repo.all()
    {:ok, assign(socket, items: items, selected: nil, ids: Enum.map(items, &(&1.id))), temporary_assigns: [:items]}
  end

  def mount(%{selected: "feed-" <> feed_id}, socket) do
    items =
      (from i in Feeds.Item,
            where: i.feed_id == ^feed_id,
            limit: 100,
            preload: [:medias, :feed])
      |> Agregat.Repo.all()
    {:ok, assign(socket, items: items, selected: nil, ids: Enum.map(items, &(&1.id))), temporary_assigns: [:items]}
  end

  def mount(%{selected: "all"}, socket) do
    items =
      (from i in Feeds.Item,
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
      {:noreply, select_item(socket, item_id)}
    end
  end

  def handle_event("toggle-favorite-" <> item_id, _, %{assigns: %{selected: selected}} = socket) do
    item = Feeds.get_item!(String.to_integer(item_id))
    case Feeds.update_item(item, %{favorite: !item.favorite}) do
      {:ok, item} ->
        {:noreply, assign(socket, items: [item])}
      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def handle_event("toggle-read-" <> item_id, _, %{assigns: %{selected: selected}} = socket) do
    item = Feeds.get_item!(String.to_integer(item_id))
    case Feeds.update_item(item, %{read: !item.read}) do
      {:ok, item} ->
        {:noreply, assign(socket, items: [item])}
      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def handle_event("keydown", %{"key" => "j"}, %{assigns: %{ids: ids, selected: selected}} = socket) do
    position = if selected != nil, do: Enum.find_index(ids, &(&1 == selected.id)), else: nil
    cond do
      position == nil ->
        {:noreply, select_item(socket, Enum.at(ids, 0))}
      position + 1 >= Enum.count(ids) ->
        {:noreply, socket}
      true ->
        {:noreply, select_item(socket, Enum.at(ids, position + 1))}
    end
  end

  def handle_event("keydown", %{"key" => "k"}, %{assigns: %{ids: ids, selected: selected}} = socket) do
    position = if selected != nil, do: Enum.find_index(ids, &(&1 == selected.id)), else: nil
    cond do
      position == nil ->
        {:noreply, select_item(socket, Enum.at(ids, 0))}
      position < 1 ->
        {:noreply, socket}
      true ->
        {:noreply, select_item(socket, Enum.at(ids, position - 1))}
    end
  end

  def handle_event("keydown", _, socket) do
    {:noreply, socket}
  end

  defp select_item(%{assigns: %{selected: selected}} = socket, item_id) do
    item = Feeds.get_item!(item_id)
    case Feeds.update_item(item, %{read: true}) do
      {:ok, item} ->
        if selected != nil do
          assign(socket, items: [selected, item], selected: item)
        else
          assign(socket, items: [item], selected: item)
        end
      {:error, %Ecto.Changeset{} = changeset} ->
        assign(socket, changeset: changeset)
    end
  end
end
