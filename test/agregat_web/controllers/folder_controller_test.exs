defmodule AgregatWeb.FolderControllerTest do
  use AgregatWeb.ConnCase

  alias Agregat.Feeds

  @create_attrs %{open: true, position: 42, title: "some title"}
  @update_attrs %{open: false, position: 43, title: "some updated title"}
  @invalid_attrs %{open: nil, position: nil, title: nil}

  def fixture(:folder) do
    {:ok, folder} = Feeds.create_folder(@create_attrs)
    folder
  end

  describe "index" do
    test "lists all folders", %{conn: conn} do
      conn = get(conn, Routes.folder_path(conn, :index))
      assert html_response(conn, 200) =~ "Listing Folders"
    end
  end

  describe "new folder" do
    test "renders form", %{conn: conn} do
      conn = get(conn, Routes.folder_path(conn, :new))
      assert html_response(conn, 200) =~ "New Folder"
    end
  end

  describe "create folder" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, Routes.folder_path(conn, :create), folder: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.folder_path(conn, :show, id)

      conn = get(conn, Routes.folder_path(conn, :show, id))
      assert html_response(conn, 200) =~ "Show Folder"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.folder_path(conn, :create), folder: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Folder"
    end
  end

  describe "edit folder" do
    setup [:create_folder]

    test "renders form for editing chosen folder", %{conn: conn, folder: folder} do
      conn = get(conn, Routes.folder_path(conn, :edit, folder))
      assert html_response(conn, 200) =~ "Edit Folder"
    end
  end

  describe "update folder" do
    setup [:create_folder]

    test "redirects when data is valid", %{conn: conn, folder: folder} do
      conn = put(conn, Routes.folder_path(conn, :update, folder), folder: @update_attrs)
      assert redirected_to(conn) == Routes.folder_path(conn, :show, folder)

      conn = get(conn, Routes.folder_path(conn, :show, folder))
      assert html_response(conn, 200) =~ "some updated title"
    end

    test "renders errors when data is invalid", %{conn: conn, folder: folder} do
      conn = put(conn, Routes.folder_path(conn, :update, folder), folder: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Folder"
    end
  end

  describe "delete folder" do
    setup [:create_folder]

    test "deletes chosen folder", %{conn: conn, folder: folder} do
      conn = delete(conn, Routes.folder_path(conn, :delete, folder))
      assert redirected_to(conn) == Routes.folder_path(conn, :index)
      assert_error_sent 404, fn ->
        get(conn, Routes.folder_path(conn, :show, folder))
      end
    end
  end

  defp create_folder(_) do
    folder = fixture(:folder)
    {:ok, folder: folder}
  end
end
