defmodule AgregatWeb.ItemComponent do
  use Phoenix.LiveComponent

  import Ecto.Query, only: [from: 2]

  alias Agregat.Feeds

  def render(assigns) do
    AgregatWeb.LiveView.render("item.html", assigns)
  end

  def preload([%{item: _item}] = list_of_assigns), do: list_of_assigns
  def preload(list_of_assigns) do
    list_of_ids = Enum.map(list_of_assigns, &(&1.id))

    items =
      (from i in Feeds.Item,
            left_join: m in assoc(i, :medias),
            left_join: f in assoc(i, :feed),
            where: i.id in ^list_of_ids,
            select: {i.id, i},
            preload: [feed: f, medias: m])
      |> Agregat.Repo.all()
      |> Map.new()

    Enum.map(list_of_assigns, fn assigns ->
      Map.put(assigns, :item, items[assigns.id])
    end)
  end

  def update(%{item: item} = assigns, socket) do
    socket = assign(socket, assigns)
    if Map.has_key?(assigns, :selected) and assigns.selected do
      case Feeds.update_item(item, %{read: true}) do
        {:ok, item} ->
          {:ok, assign(socket, item: item, selected: true)}
        {:error, %Ecto.Changeset{} = changeset} ->
          {:ok, assign(socket, changeset: changeset)}
      end
    else
      {:ok, socket}
    end
  end

  def mount(socket) do
    {:ok, assign(socket, selected: false), temporary_assigns: [item: nil]}
  end

  def handle_event("toggle-favorite", _, %{assigns: %{id: id}} = socket) do
    item = Feeds.get_item!(id, user_id: socket.assigns.user.id)
    case Feeds.update_item(item, %{favorite: !item.favorite}) do
      {:ok, item} ->
        {:noreply, assign(socket, item: item)}
      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def handle_event("toggle-read", _, %{assigns: %{id: id}} = socket) do
    item = Feeds.get_item!(id, user_id: socket.assigns.user.id)
    case Feeds.update_item(item, %{read: !item.read}) do
      {:ok, item} ->
        {:noreply, assign(socket, item: item)}
      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
