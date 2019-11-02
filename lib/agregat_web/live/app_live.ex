defmodule AgregatWeb.AppLive do
  use Phoenix.LiveView

  alias Agregat.Feeds
  alias AgregatWeb.Router.Helpers, as: Routes

  import Ecto.Query, only: [from: 2]

  def render(assigns) do
    AgregatWeb.LiveView.render("app.html", assigns)
  end

  def mount(session, socket) do
    user = get_user(session.agregat_auth)
    if user do
      Phoenix.PubSub.subscribe(Agregat.PubSub, "folders")
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
        %{} -> "all"
      end
    {:noreply, assign(socket, params: params, selected: selected)}
  end

  def handle_event("toggle-folder-" <> folder_id, _, socket) do
    folder_id = String.to_integer(folder_id)
    folder = Enum.find(socket.assigns.folders, &(&1.id == folder_id))
    case Feeds.update_folder(folder, %{open: !folder.open}) do
      {:ok, folder} -> {:noreply, socket}
      {:error, %Ecto.Changeset{} = changeset} -> {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def handle_event("select-folder-" <> folder_id, _, %{assigns: %{params: params}} = socket) do
    params = params |> Map.drop(["feed_id", "favorite"]) |> Map.put("folder_id", folder_id)
    {:noreply, live_redirect(socket, to: Routes.live_path(socket, __MODULE__, params))}
  end

  def handle_event("select-feed-" <> feed_id, _, %{assigns: %{params: params}} = socket) do
    params = params |> Map.drop(["folder_id", "favorite"]) |> Map.put("feed_id", feed_id)
    {:noreply, live_redirect(socket, to: Routes.live_path(socket, __MODULE__, params))}
  end

  def handle_event("select-favorites", _, %{assigns: %{params: params}} = socket) do
    params = params |> Map.drop(["feed_id", "folder_id"]) |> Map.put("favorite", true)
    {:noreply, live_redirect(socket, to: Routes.live_path(socket, __MODULE__, params))}
  end

  def handle_event("select-all", _, %{assigns: %{params: params}} = socket) do
    params = params |> Map.drop(["feed_id", "folder_id", "favorite"])
    {:noreply, live_redirect(socket, to: Routes.live_path(socket, __MODULE__, params))}
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

  defp get_user(token) do
    case Pow.Store.CredentialsCache.get([backend: Pow.Store.Backend.EtsCache], token) do
      {user, _} -> user
      _ -> nil
    end
  end
end
