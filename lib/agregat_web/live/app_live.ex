defmodule AgregatWeb.AppLive do
  use AgregatWeb, :live_view

  alias Agregat.Feeds
  alias AgregatWeb.Router.Helpers, as: Routes

  def render(assigns) do
    AgregatWeb.LiveView.render("app.html", assigns)
  end

  def mount(_params, session, socket) do
    socket = assign_defaults(session, socket)
    if socket.assigns.current_user do
      if connected?(socket) do
        Phoenix.PubSub.subscribe(Agregat.PubSub, "folders")
        Phoenix.PubSub.subscribe(Agregat.PubSub, "feeds")
      end
      folders = Feeds.list_folders(user_id: socket.assigns.current_user.id)
      {:ok, assign(socket, folders: folders, items: [], selected: nil, total_unread: 0, menu_open: nil, mode: :items)}
    else
      {:error, "Unauthorized"}
    end
  end

  def handle_params(params, _, socket) do
    selected =
      case params do
        %{"folder_id" => folder_id} -> "folder-#{folder_id}"
        %{"feed_id" => feed_id} -> "feed-#{feed_id}"
        %{"favorite" => _} -> "favorites"
        %{"all" => _} -> "all"
        %{} -> "none"
      end
    {:noreply, assign(socket, params: params, selected: selected)}
  end

  def handle_event("toggle-folder-" <> id, _, socket) do
    id = String.to_integer(id)
    folder = Enum.find(socket.assigns.folders, &(&1.id == id))
    case Feeds.update_folder(folder, %{open: !folder.open}) do
      {:ok, _} -> {:noreply, socket}
      {:error, %Ecto.Changeset{} = changeset} -> {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def handle_event("toggle-menu-" <> element, _, socket) do
    {:noreply, assign(socket, menu_open: (if socket.assigns.menu_open == element, do: nil, else: element))}
  end

  def handle_event("delete-folder-" <> id, _, socket) do
    folder = Feeds.get_folder!(id, user_id: socket.assigns.current_user.id)
    Feeds.delete_folder(folder)
    {:noreply, socket}
  end

  def handle_event("delete-feed-" <> id, _, socket) do
    feed = Feeds.get_feed!(id, user_id: socket.assigns.current_user.id)
    Feeds.delete_feed(feed)
    {:noreply, socket}
  end

  def handle_event("select-folder-" <> id, _, %{assigns: %{params: params}} = socket) do
    params = params |> Map.drop(["all", "feed_id", "favorite"]) |> Map.put("folder_id", id)
    {:noreply, push_patch(socket, to: Routes.live_path(socket, __MODULE__, params))}
  end

  def handle_event("select-feed-" <> id, _, %{assigns: %{params: params}} = socket) do
    params = params |> Map.drop(["all", "folder_id", "favorite"]) |> Map.put("feed_id", id)
    {:noreply, push_patch(socket, to: Routes.live_path(socket, __MODULE__, params))}
  end

  def handle_event("select-favorites", _, %{assigns: %{params: params}} = socket) do
    params = params |> Map.drop(["all", "feed_id", "folder_id"]) |> Map.put("favorite", true)
    {:noreply, push_patch(socket, to: Routes.live_path(socket, __MODULE__, params))}
  end

  def handle_event("select-all", _, %{assigns: %{params: params}} = socket) do
    params = params |> Map.drop(["feed_id", "folder_id", "favorite"]) |> Map.put("all", true)
    {:noreply, push_patch(socket, to: Routes.live_path(socket, __MODULE__, params))}
  end

  def handle_event("select-none", _, %{assigns: %{params: params}} = socket) do
    params = params |> Map.drop(["feed_id", "folder_id", "favorite", "all"])
    {:noreply, push_patch(socket, to: Routes.live_path(socket, __MODULE__, params))}
  end

  def handle_event("toggle-read-filter", _, %{assigns: %{params: params}} = socket) do
    params =
      if params["read"] == "false" do
        Map.delete(params, "read")
      else
        Map.put(params, "read", "false")
      end
    {:noreply, push_patch(socket, to: Routes.live_path(socket, __MODULE__, params))}
  end

  def handle_event("mark-folder-read-" <> folder_id, _, socket) do
    Feeds.update_folder_items(String.to_integer(folder_id), %{read: true})
    {:noreply, socket}
  end

  def handle_event("mark-folder-unread-" <> folder_id, _, socket) do
    Feeds.update_folder_items(String.to_integer(folder_id), %{read: false})
    {:noreply, socket}
  end

  def handle_event("mark-feed-read-" <> feed_id, _, socket) do
    Feeds.update_feed_items(String.to_integer(feed_id), %{read: true})
    {:noreply, socket}
  end

  def handle_event("mark-feed-unread-" <> feed_id, _, socket) do
    Feeds.update_feed_items(String.to_integer(feed_id), %{read: false})
    {:noreply, socket}
  end

  def handle_event("keydown", %{"key" => "h"}, %{assigns: %{selected: selected}} = socket) do
    list = get_selection_list(socket.assigns.current_user.id)
    index = Enum.find_index(list, &(&1 == selected))
    if index != nil and index > 0 do
      new_selection = Enum.at(list, index - 1)
      if new_selection do
        handle_event("select-#{new_selection}", %{}, socket)
      else
        {:noreply, socket}
      end
    else
      handle_event("select-all", %{}, socket)
    end
  end

  def handle_event("keydown", %{"key" => "l"}, %{assigns: %{selected: selected}} = socket) do
    list = get_selection_list(socket.assigns.current_user.id)
    index = Enum.find_index(list, &(&1 == selected))
    if index != nil do
      new_selection = Enum.at(list, index + 1)
      if new_selection do
        handle_event("select-#{new_selection}", %{}, socket)
      else
        {:noreply, socket}
      end
    else
      handle_event("select-all", %{}, socket)
    end
  end

  def handle_event("keydown", %{"key" => "i"} = value, socket) do
    handle_event("toggle-read-filter", value, socket)
  end

  def handle_event("keydown", _, socket) do
    {:noreply, socket}
  end

  def handle_info(%{folders: folders, user_id: user_id}, socket) do
    if user_id == socket.assigns.current_user.id do
      {:noreply, assign(socket, folders: folders)}
    else
      {:noreply, socket}
    end
  end

  def handle_info(%{feeds: _, user_id: user_id}, socket) do
    if user_id == socket.assigns.current_user.id do
      folders = Feeds.list_folders(user_id: user_id)
      {:noreply, assign(socket, folders: folders)}
    else
      {:noreply, socket}
    end
  end

  defp get_selection_list(user_id) do
    ["all", "favorites"] ++ (
      Feeds.list_folders(user_id: user_id)
      |> Enum.flat_map(fn f -> ["folder-#{f.id}"] ++ if f.open, do: Enum.map(f.feeds, &("feed-#{&1.id}")), else: [] end)
    )
  end
end
