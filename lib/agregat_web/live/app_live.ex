defmodule AgregatWeb.AppLive do
  use Phoenix.LiveView

  alias Agregat.Feeds
  alias AgregatWeb.Router.Helpers, as: Routes

  def render(assigns) do
    AgregatWeb.LiveView.render("app.html", assigns)
  end

  def mount(session, socket) do
    user = get_user(session.agregat_auth)
    if user do
      Phoenix.PubSub.subscribe(Agregat.PubSub, "folders")
      Phoenix.PubSub.subscribe(Agregat.PubSub, "feeds")
      folders = Feeds.list_folders(user_id: user.id)
      {:ok, assign(socket, folders: folders, items: [], selected: nil, total_unread: 0, menu_open: nil, user: user)}
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
        %{} -> nil
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
    folder = Feeds.get_folder!(id, user_id: socket.assigns.user.id)
    Feeds.delete_folder(folder)
    {:noreply, socket}
  end

  def handle_event("delete-feed-" <> id, _, socket) do
    feed = Feeds.get_feed!(id, user_id: socket.assigns.user.id)
    Feeds.delete_feed(feed)
    {:noreply, socket}
  end

  def handle_event("select-folder-" <> id, _, %{assigns: %{params: params}} = socket) do
    params = params |> Map.drop(["all", "feed_id", "favorite"]) |> Map.put("folder_id", id)
    {:noreply, live_redirect(socket, to: Routes.live_path(socket, __MODULE__, params))}
  end

  def handle_event("select-feed-" <> id, _, %{assigns: %{params: params}} = socket) do
    params = params |> Map.drop(["all", "folder_id", "favorite"]) |> Map.put("feed_id", id)
    {:noreply, live_redirect(socket, to: Routes.live_path(socket, __MODULE__, params))}
  end

  def handle_event("select-favorites", _, %{assigns: %{params: params}} = socket) do
    params = params |> Map.drop(["all", "feed_id", "folder_id"]) |> Map.put("favorite", true)
    {:noreply, live_redirect(socket, to: Routes.live_path(socket, __MODULE__, params))}
  end

  def handle_event("select-all", _, %{assigns: %{params: params}} = socket) do
    params = params |> Map.drop(["feed_id", "folder_id", "favorite"]) |> Map.put("all", true)
    {:noreply, live_redirect(socket, to: Routes.live_path(socket, __MODULE__, params))}
  end

  def handle_event("next-item", _, %{assigns: %{user: user}} = socket) do
    Phoenix.PubSub.broadcast(Agregat.PubSub, "item-selection-#{user.id}", %{action: "next"})
    {:noreply, socket}
  end

  def handle_event("previous-item", _, %{assigns: %{user: user}} = socket) do
    Phoenix.PubSub.broadcast(Agregat.PubSub, "item-selection-#{user.id}", %{action: "previous"})
    {:noreply, socket}
  end

  def handle_event("toggle-read-filter", _, %{assigns: %{params: params}} = socket) do
    params =
      if params["read"] == "false" do
        Map.delete(params, "read")
      else
        Map.put(params, "read", "false")
      end
    {:noreply, live_redirect(socket, to: Routes.live_path(socket, __MODULE__, params))}
  end

  def handle_event("keydown", %{"key" => "h"}, socket) do
    {:noreply, socket}
  end

  def handle_event("keydown", %{"key" => "l"}, socket) do
    {:noreply, socket}
  end

  def handle_event("keydown", %{"key" => "i"} = value, socket) do
    handle_event("toggle-read-filter", value, socket)
  end

  def handle_event("keydown", _, socket) do
    {:noreply, socket}
  end

  def handle_info(%{folders: folders, user_id: user_id}, socket) do
    if user_id == socket.assigns.user.id do
      {:noreply, assign(socket, folders: folders)}
    else
      {:noreply, socket}
    end
  end

  def handle_info(%{feeds: _, user_id: user_id}, socket) do
    if user_id == socket.assigns.user.id do
      folders = Feeds.list_folders(user_id: user_id)
      {:noreply, assign(socket, folders: folders)}
    else
      {:noreply, socket}
    end
  end

  defp get_user(token) do
    case Pow.Store.CredentialsCache.get([backend: Pow.Store.Backend.EtsCache], token) do
      {user, _} -> user
      _ -> nil
    end
  end
end
