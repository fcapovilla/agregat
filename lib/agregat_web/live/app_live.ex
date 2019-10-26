defmodule AgregatWeb.AppLive do
  use Phoenix.LiveView

  alias Agregat.Feeds
  alias AgregatWeb.Router.Helpers, as: Routes

  import Ecto.Query, only: [from: 2]

  def render(assigns) do
    AgregatWeb.LiveView.render("app.html", assigns)
  end

  def mount(session, socket) do
    folders = Feeds.list_folders()
    {:ok, assign(socket, folders: folders, items: [], selected: nil, total_unread: 0, menu_open: nil)}
  end

  def handle_params(%{"folder_id" => folder_id}, _, socket) do
    {:noreply, assign(socket, selected: "folder-#{folder_id}")}
  end

  def handle_params(%{"feed_id" => feed_id}, _, socket) do
    {:noreply, assign(socket, selected: "feed-#{feed_id}")}
  end

  def handle_params(%{}, _, socket) do
    {:noreply, assign(socket, selected: "all")}
  end

  def handle_event("toggle-folder-" <> folder_id, _, socket) do
    folder_id = String.to_integer(folder_id)
    folder = Enum.find(socket.assigns.folders, &(&1.id == folder_id))
    case Feeds.update_folder(folder, %{open: !folder.open}) do
      {:ok, folder} ->
        folders = Feeds.list_folders()
        {:noreply, assign(socket, folders: folders)}
      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def handle_event("select-folder-" <> folder_id, _, socket) do
    folder_id = String.to_integer(folder_id)
    {:noreply, live_redirect(socket, to: "/folder/#{folder_id}")}
  end

  def handle_event("select-feed-" <> feed_id, _, socket) do
    feed_id = String.to_integer(feed_id)
    {:noreply, live_redirect(socket, to: "/feed/#{feed_id}")}
  end

  def handle_event("select-all", _, socket) do
    {:noreply, live_redirect(socket, to: "/")}
  end

  def handle_event("keydown", %{"key" => "h"}, socket) do
    {:noreply, socket}
  end

  def handle_event("keydown", %{"key" => "l"}, socket) do
    {:noreply, socket}
  end

  def handle_event("keydown", _, socket) do
    {:noreply, socket}
  end
end
