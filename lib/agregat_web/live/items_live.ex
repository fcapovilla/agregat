defmodule AgregatWeb.ItemsLive do
  @moduledoc """
  This LiveView displays a list of feed items, sorted by date and filtered by the received params.
  """

  use AgregatWeb, :live_view

  alias Agregat.Feeds

  @doc """
  Mounts the LiveView.
  """
  def mount(_params, %{"params" => params} = session, socket) do
    socket = assign_defaults(session, socket)

    if connected?(socket) do
      case params do
        %{"folder_id" => folder_id} ->
          Phoenix.PubSub.subscribe(Agregat.PubSub, "folder-#{folder_id}")

        %{"feed_id" => feed_id} ->
          Phoenix.PubSub.subscribe(Agregat.PubSub, "feed-#{feed_id}")

        _ ->
          Phoenix.PubSub.subscribe(Agregat.PubSub, "items")
      end
    end

    {:ok,
     assign(socket, page: 1, params: params, items: [])
     |> fetch_items(), temporary_assigns: [items: []]}
  end

  # Toggles the `favorite` value of an item.
  def handle_event("toggle-favorite-" <> item_id, _, socket) do
    item = Feeds.get_item!(String.to_integer(item_id), user_id: socket.assigns.current_user.id)

    case Feeds.update_item(item, %{favorite: !item.favorite}) do
      {:ok, item} ->
        {:noreply, assign(socket, items: [item])}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  # Toggles the `read` value of an item.
  def handle_event("toggle-read-" <> item_id, _, socket) do
    item = Feeds.get_item!(String.to_integer(item_id), user_id: socket.assigns.current_user.id)

    case Feeds.update_item(item, %{read: !item.read}) do
      {:ok, item} ->
        {:noreply, assign(socket, items: [item])}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  # Sets the `read` value of an item.
  def handle_event("set-read-" <> item_id, %{"read" => read}, socket) do
    item = Feeds.get_item!(String.to_integer(item_id), user_id: socket.assigns.current_user.id)

    case Feeds.update_item(item, %{read: read}) do
      {:ok, item} ->
        {:noreply, assign(socket, items: [item])}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  # Fetches another page of items.
  def handle_event("load-more", _, %{assigns: %{page: page}} = socket) do
    {:noreply, assign(socket, page: page + 1) |> fetch_items()}
  end

  # Receives item updates from the PubSub Channel.
  def handle_info(%{items: items, user_id: user_id}, socket) do
    if user_id == socket.assigns.current_user.id do
      items =
        if socket.assigns.params["read"] == "false" do
          Enum.filter(items, &(!&1.read))
        else
          items
        end

      {:noreply, assign(socket, items: items)}
    else
      {:noreply, socket}
    end
  end

  defp fetch_items(%{assigns: %{params: params, page: page}} = socket) do
    filter = params |> Map.put(:user_id, socket.assigns.current_user.id) |> Map.drop(["all"])
    items = Feeds.list_items(filter, %{page: page})
    assign(socket, items: items)
  end
end
