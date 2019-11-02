defmodule AgregatWeb.FolderController do
  use AgregatWeb, :controller

  alias Agregat.Feeds
  alias Agregat.Feeds.Folder

  def new(conn, _params) do
    changeset = Feeds.change_folder(%Folder{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"folder" => folder_params}) do
    case Feeds.create_folder(folder_params) do
      {:ok, folder} ->
        conn
        |> put_flash(:info, "Folder created successfully.")
        |> redirect(to: Routes.live_path(conn, AgregatWeb.AppLive))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def edit(conn, %{"id" => id}) do
    folder = Feeds.get_folder!(id)
    changeset = Feeds.change_folder(folder)
    render(conn, "edit.html", folder: folder, changeset: changeset)
  end

  def update(conn, %{"id" => id, "folder" => folder_params}) do
    folder = Feeds.get_folder!(id)

    case Feeds.update_folder(folder, folder_params) do
      {:ok, folder} ->
        conn
        |> put_flash(:info, "Folder updated successfully.")
        |> redirect(to: Routes.live_path(conn, AgregatWeb.AppLive))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", folder: folder, changeset: changeset)
    end
  end
end
