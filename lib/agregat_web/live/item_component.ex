defmodule AgregatWeb.ItemComponent do
  use AgregatWeb, :live_component

  import Ecto.Query, only: [from: 2]

  alias Agregat.Feeds

  def preload([%{item: _item}] = list_of_assigns), do: list_of_assigns

  def preload(list_of_assigns) do
    list_of_ids = Enum.map(list_of_assigns, & &1.id)

    items =
      from(i in Feeds.Item,
        left_join: m in assoc(i, :medias),
        left_join: f in assoc(i, :feed),
        where: i.id in ^list_of_ids,
        select: {i.id, i},
        preload: [feed: f, medias: m]
      )
      |> Agregat.Repo.all()
      |> Map.new()

    Enum.map(list_of_assigns, fn assigns ->
      Map.put(assigns, :item, items[assigns.id])
    end)
  end

  def mount(socket) do
    {:ok, socket, temporary_assigns: [item: nil]}
  end

  def handle_event("toggle-favorite", _, %{assigns: %{id: id}} = socket) do
    item = Feeds.get_item!(id, user_id: socket.assigns.current_user.id)

    case Feeds.update_item(item, %{favorite: !item.favorite}) do
      {:ok, item} ->
        {:noreply, assign(socket, item: item)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def handle_event("toggle-read", _, %{assigns: %{id: id}} = socket) do
    item = Feeds.get_item!(id, user_id: socket.assigns.current_user.id)

    case Feeds.update_item(item, %{read: !item.read}) do
      {:ok, item} ->
        {:noreply, assign(socket, item: item)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def handle_event("set-read", %{"read" => read}, %{assigns: %{id: id}} = socket) do
    item = Feeds.get_item!(id, user_id: socket.assigns.current_user.id)

    case Feeds.update_item(item, %{read: read}) do
      {:ok, item} ->
        {:noreply, assign(socket, item: item)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
