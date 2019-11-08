defmodule AgregatWeb.ReaderLive do
  use Phoenix.LiveView

  import Ecto.Query, only: [from: 2, subquery: 1]

  alias Agregat.Feeds

  def render(assigns) do
    AgregatWeb.LiveView.render("reader.html", assigns)
  end

  def mount(%{params: params, user: user}, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Agregat.PubSub, "item-selection-#{user.id}")
    end
    {:ok, assign(socket, selected: nil, params: params, items: [], prev: nil, next: nil, user: user)
          |> fetch_items(), temporary_assigns: [items: []]}
  end

  def handle_event("open-item-" <> item_id, _, %{assigns: %{selected: selected}} = socket) do
    item_id = String.to_integer(item_id)
    if selected != nil and selected.id == item_id do
      {:noreply, socket}
    else
      {:noreply, select_item(socket, item_id)}
    end
  end

  def handle_event("toggle-favorite-" <> item_id, _, socket) do
    item = Feeds.get_item!(String.to_integer(item_id), user_id: socket.assigns.user.id)
    case Feeds.update_item(item, %{favorite: !item.favorite}) do
      {:ok, _} ->
        {:noreply, fetch_items(socket)}
      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def handle_event("toggle-read-" <> item_id, _, socket) do
    item = Feeds.get_item!(String.to_integer(item_id), user_id: socket.assigns.user.id)
    case Feeds.update_item(item, %{read: !item.read}) do
      {:ok, _} ->
        {:noreply, fetch_items(socket)}
      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def handle_event("next-item", _, %{assigns: %{next: next}} = socket) do
    if next != nil do
      {:noreply, select_item(socket, next)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("previous-item", _, %{assigns: %{prev: prev}} = socket) do
    if prev != nil do
      {:noreply, select_item(socket, prev)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("keydown", %{"key" => "j"}, socket) do
    handle_event("next-item", nil, socket)
  end

  def handle_event("keydown", %{"key" => "k"}, socket) do
    handle_event("previous-item", nil, socket)
  end

  def handle_event("keydown", _, socket) do
    {:noreply, socket}
  end

  defp fetch_items(%{assigns: %{selected: nil}} = socket) do
    items =
      (from i in Feeds.Item, preload: [:medias, :feed], limit: 30, order_by: [desc: :date, desc: :id])
      |> filter(socket)
      |> Feeds.filter_by(user_id: socket.assigns.user.id)
      |> Agregat.Repo.all()
    ids = Enum.map(items, &(&1.id))
    assign(socket,
      items: items,
      next: Enum.at(ids, 1),
      prev: Enum.at(ids, 0),
      selected: (if items != [], do: Enum.at(items, 0), else: nil)
    )
  end

  defp fetch_items(%{assigns: %{selected: selected}} = socket) do
    base_query = Feeds.Item |> filter(socket) |> Feeds.filter_by(user_id: socket.assigns.user.id)
    items = Agregat.Repo.all(
      from i in subquery(
        from s in subquery(from i in base_query, where: i.date <= ^(selected.date), order_by: [desc: :date, desc: :id], limit: 20),
        union_all: ^subquery(from i in base_query, where: i.date > ^(selected.date), order_by: [asc: :date, asc: :id], limit: 10),
        union_all: ^subquery(from i in Feeds.Item, where: i.id == ^(selected.id))
      ),
      preload: [:medias, :feed],
      order_by: [desc: :date, desc: :id]
    ) |> Enum.uniq_by(&(&1.id))
    ids = Enum.map(items, &(&1.id))
    index = Enum.find_index(ids, &(&1 == selected.id))
    next = Enum.at(ids, index + 1)
    prev = if index > 0, do: Enum.at(ids, index - 1), else: nil
    assign(socket, items: items, next: next, prev: prev)
  end

  defp select_item(socket, item_id) do
    item = Feeds.get_item!(item_id, user_id: socket.assigns.user.id)
    case Feeds.update_item(item, %{read: true}) do
      {:ok, item} ->
        fetch_items(assign(socket, selected: item))
      {:error, %Ecto.Changeset{} = changeset} ->
        assign(socket, changeset: changeset)
    end
  end

  defp filter(query, %{assigns: %{params: params}} = _socket) do
    Enum.reduce(params, query, fn {key, value}, query ->
      case key do
        "favorite" -> from i in query, where: i.favorite == ^(if value == "true", do: true, else: false)
        "read" -> from i in query, where: i.read == ^(if value == "true", do: true, else: false)
        "folder_id" -> from i in query, left_join: f in assoc(i, :feed), where: f.folder_id == ^value
        "feed_id" -> from i in query, where: i.feed_id == ^value
        _ -> query
      end
    end)
  end

  def handle_info(%{action: "next"}, socket) do
    handle_event("next-item", nil, socket)
  end

  def handle_info(%{action: "previous"}, socket) do
    handle_event("previous-item", nil, socket)
  end
end
