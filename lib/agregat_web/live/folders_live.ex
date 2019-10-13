defmodule AgregatWeb.FoldersLive do
  use Phoenix.LiveView

  alias Agregat.Feeds
  alias AgregatWeb.Router.Helpers, as: Routes

  def render(assigns) do
    AgregatWeb.LiveView.render("folders.html", assigns)
  end

  def mount(%{selected: selected}, socket) do
    folders = Feeds.list_folders()
    {:ok, assign(socket, folders: folders, selected: selected, total_unread: 0, menu_open: nil)}
  end

  def handle_event("toggle-folder-" <> folder_id, _, socket) do
    folder_id = String.to_integer(folder_id)
    folder = Enum.find(socket.assigns.folders, &(&1.id == folder_id))
    folder_params = if folder.open do
      %{open: false}
    else
      %{open: true}
    end

    case Feeds.update_folder(folder, folder_params) do
      {:ok, folder} ->
        folders = Feeds.list_folders()
        {:noreply, assign(socket, folders: folders)}
      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def handle_event("select-folder-" <> folder_id, _, socket) do
    folder_id = String.to_integer(folder_id)
    {:stop, redirect(socket, to: Routes.folder_path(socket, :show, folder_id))}
  end

  def handle_event("select-feed-" <> feed_id, _, socket) do
    feed_id = String.to_integer(feed_id)
    {:stop, redirect(socket, to: Routes.feed_path(socket, :show, feed_id))}
  end

  def handle_event("select-all", _, socket) do
    {:stop, redirect(socket, to: Routes.item_path(socket, :index))}
  end
end
