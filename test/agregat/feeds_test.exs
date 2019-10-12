defmodule Agregat.FeedsTest do
  use Agregat.DataCase

  alias Agregat.Feeds

  describe "favicons" do
    alias Agregat.Feeds.Favicon

    @valid_attrs %{data: "some data", host: "some host"}
    @update_attrs %{data: "some updated data", host: "some updated host"}
    @invalid_attrs %{data: nil, host: nil}

    def favicon_fixture(attrs \\ %{}) do
      {:ok, favicon} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Feeds.create_favicon()

      favicon
    end

    test "list_favicons/0 returns all favicons" do
      favicon = favicon_fixture()
      assert Feeds.list_favicons() == [favicon]
    end

    test "get_favicon!/1 returns the favicon with given id" do
      favicon = favicon_fixture()
      assert Feeds.get_favicon!(favicon.id) == favicon
    end

    test "create_favicon/1 with valid data creates a favicon" do
      assert {:ok, %Favicon{} = favicon} = Feeds.create_favicon(@valid_attrs)
      assert favicon.data == "some data"
      assert favicon.host == "some host"
    end

    test "create_favicon/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Feeds.create_favicon(@invalid_attrs)
    end

    test "update_favicon/2 with valid data updates the favicon" do
      favicon = favicon_fixture()
      assert {:ok, %Favicon{} = favicon} = Feeds.update_favicon(favicon, @update_attrs)
      assert favicon.data == "some updated data"
      assert favicon.host == "some updated host"
    end

    test "update_favicon/2 with invalid data returns error changeset" do
      favicon = favicon_fixture()
      assert {:error, %Ecto.Changeset{}} = Feeds.update_favicon(favicon, @invalid_attrs)
      assert favicon == Feeds.get_favicon!(favicon.id)
    end

    test "delete_favicon/1 deletes the favicon" do
      favicon = favicon_fixture()
      assert {:ok, %Favicon{}} = Feeds.delete_favicon(favicon)
      assert_raise Ecto.NoResultsError, fn -> Feeds.get_favicon!(favicon.id) end
    end

    test "change_favicon/1 returns a favicon changeset" do
      favicon = favicon_fixture()
      assert %Ecto.Changeset{} = Feeds.change_favicon(favicon)
    end
  end

  describe "folders" do
    alias Agregat.Feeds.Folder

    @valid_attrs %{open: true, position: 42, title: "some title"}
    @update_attrs %{open: false, position: 43, title: "some updated title"}
    @invalid_attrs %{open: nil, position: nil, title: nil}

    def folder_fixture(attrs \\ %{}) do
      {:ok, folder} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Feeds.create_folder()

      folder
    end

    test "list_folders/0 returns all folders" do
      folder = folder_fixture()
      assert Feeds.list_folders() == [folder]
    end

    test "get_folder!/1 returns the folder with given id" do
      folder = folder_fixture()
      assert Feeds.get_folder!(folder.id) == folder
    end

    test "create_folder/1 with valid data creates a folder" do
      assert {:ok, %Folder{} = folder} = Feeds.create_folder(@valid_attrs)
      assert folder.open == true
      assert folder.position == 42
      assert folder.title == "some title"
    end

    test "create_folder/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Feeds.create_folder(@invalid_attrs)
    end

    test "update_folder/2 with valid data updates the folder" do
      folder = folder_fixture()
      assert {:ok, %Folder{} = folder} = Feeds.update_folder(folder, @update_attrs)
      assert folder.open == false
      assert folder.position == 43
      assert folder.title == "some updated title"
    end

    test "update_folder/2 with invalid data returns error changeset" do
      folder = folder_fixture()
      assert {:error, %Ecto.Changeset{}} = Feeds.update_folder(folder, @invalid_attrs)
      assert folder == Feeds.get_folder!(folder.id)
    end

    test "delete_folder/1 deletes the folder" do
      folder = folder_fixture()
      assert {:ok, %Folder{}} = Feeds.delete_folder(folder)
      assert_raise Ecto.NoResultsError, fn -> Feeds.get_folder!(folder.id) end
    end

    test "change_folder/1 returns a folder changeset" do
      folder = folder_fixture()
      assert %Ecto.Changeset{} = Feeds.change_folder(folder)
    end
  end

  describe "feeds" do
    alias Agregat.Feeds.Feed

    @valid_attrs %{auto_frequency: true, last_sync: "2010-04-17T14:00:00Z", position: 42, sync_status: "some sync_status", title: "some title", unread_count: 42, update_frequency: 42, url: "some url"}
    @update_attrs %{auto_frequency: false, last_sync: "2011-05-18T15:01:01Z", position: 43, sync_status: "some updated sync_status", title: "some updated title", unread_count: 43, update_frequency: 43, url: "some updated url"}
    @invalid_attrs %{auto_frequency: nil, last_sync: nil, position: nil, sync_status: nil, title: nil, unread_count: nil, update_frequency: nil, url: nil}

    def feed_fixture(attrs \\ %{}) do
      {:ok, feed} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Feeds.create_feed()

      feed
    end

    test "list_feeds/0 returns all feeds" do
      feed = feed_fixture()
      assert Feeds.list_feeds() == [feed]
    end

    test "get_feed!/1 returns the feed with given id" do
      feed = feed_fixture()
      assert Feeds.get_feed!(feed.id) == feed
    end

    test "create_feed/1 with valid data creates a feed" do
      assert {:ok, %Feed{} = feed} = Feeds.create_feed(@valid_attrs)
      assert feed.auto_frequency == true
      assert feed.last_sync == DateTime.from_naive!(~N[2010-04-17T14:00:00Z], "Etc/UTC")
      assert feed.position == 42
      assert feed.sync_status == "some sync_status"
      assert feed.title == "some title"
      assert feed.unread_count == 42
      assert feed.update_frequency == 42
      assert feed.url == "some url"
    end

    test "create_feed/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Feeds.create_feed(@invalid_attrs)
    end

    test "update_feed/2 with valid data updates the feed" do
      feed = feed_fixture()
      assert {:ok, %Feed{} = feed} = Feeds.update_feed(feed, @update_attrs)
      assert feed.auto_frequency == false
      assert feed.last_sync == DateTime.from_naive!(~N[2011-05-18T15:01:01Z], "Etc/UTC")
      assert feed.position == 43
      assert feed.sync_status == "some updated sync_status"
      assert feed.title == "some updated title"
      assert feed.unread_count == 43
      assert feed.update_frequency == 43
      assert feed.url == "some updated url"
    end

    test "update_feed/2 with invalid data returns error changeset" do
      feed = feed_fixture()
      assert {:error, %Ecto.Changeset{}} = Feeds.update_feed(feed, @invalid_attrs)
      assert feed == Feeds.get_feed!(feed.id)
    end

    test "delete_feed/1 deletes the feed" do
      feed = feed_fixture()
      assert {:ok, %Feed{}} = Feeds.delete_feed(feed)
      assert_raise Ecto.NoResultsError, fn -> Feeds.get_feed!(feed.id) end
    end

    test "change_feed/1 returns a feed changeset" do
      feed = feed_fixture()
      assert %Ecto.Changeset{} = Feeds.change_feed(feed)
    end
  end

  describe "items" do
    alias Agregat.Feeds.Item

    @valid_attrs %{content: "some content", date: ~N[2010-04-17 14:00:00], favorite: true, guid: "some guid", orig_feed_title: "some orig_feed_title", read: true, title: "some title", url: "some url"}
    @update_attrs %{content: "some updated content", date: ~N[2011-05-18 15:01:01], favorite: false, guid: "some updated guid", orig_feed_title: "some updated orig_feed_title", read: false, title: "some updated title", url: "some updated url"}
    @invalid_attrs %{content: nil, date: nil, favorite: nil, guid: nil, orig_feed_title: nil, read: nil, title: nil, url: nil}

    def item_fixture(attrs \\ %{}) do
      {:ok, item} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Feeds.create_item()

      item
    end

    test "list_items/0 returns all items" do
      item = item_fixture()
      assert Feeds.list_items() == [item]
    end

    test "get_item!/1 returns the item with given id" do
      item = item_fixture()
      assert Feeds.get_item!(item.id) == item
    end

    test "create_item/1 with valid data creates a item" do
      assert {:ok, %Item{} = item} = Feeds.create_item(@valid_attrs)
      assert item.content == "some content"
      assert item.date == ~N[2010-04-17 14:00:00]
      assert item.favorite == true
      assert item.guid == "some guid"
      assert item.orig_feed_title == "some orig_feed_title"
      assert item.read == true
      assert item.title == "some title"
      assert item.url == "some url"
    end

    test "create_item/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Feeds.create_item(@invalid_attrs)
    end

    test "update_item/2 with valid data updates the item" do
      item = item_fixture()
      assert {:ok, %Item{} = item} = Feeds.update_item(item, @update_attrs)
      assert item.content == "some updated content"
      assert item.date == ~N[2011-05-18 15:01:01]
      assert item.favorite == false
      assert item.guid == "some updated guid"
      assert item.orig_feed_title == "some updated orig_feed_title"
      assert item.read == false
      assert item.title == "some updated title"
      assert item.url == "some updated url"
    end

    test "update_item/2 with invalid data returns error changeset" do
      item = item_fixture()
      assert {:error, %Ecto.Changeset{}} = Feeds.update_item(item, @invalid_attrs)
      assert item == Feeds.get_item!(item.id)
    end

    test "delete_item/1 deletes the item" do
      item = item_fixture()
      assert {:ok, %Item{}} = Feeds.delete_item(item)
      assert_raise Ecto.NoResultsError, fn -> Feeds.get_item!(item.id) end
    end

    test "change_item/1 returns a item changeset" do
      item = item_fixture()
      assert %Ecto.Changeset{} = Feeds.change_item(item)
    end
  end

  describe "medias" do
    alias Agregat.Feeds.Media

    @valid_attrs %{type: "some type", url: "some url"}
    @update_attrs %{type: "some updated type", url: "some updated url"}
    @invalid_attrs %{type: nil, url: nil}

    def media_fixture(attrs \\ %{}) do
      {:ok, media} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Feeds.create_media()

      media
    end

    test "list_medias/0 returns all medias" do
      media = media_fixture()
      assert Feeds.list_medias() == [media]
    end

    test "get_media!/1 returns the media with given id" do
      media = media_fixture()
      assert Feeds.get_media!(media.id) == media
    end

    test "create_media/1 with valid data creates a media" do
      assert {:ok, %Media{} = media} = Feeds.create_media(@valid_attrs)
      assert media.type == "some type"
      assert media.url == "some url"
    end

    test "create_media/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Feeds.create_media(@invalid_attrs)
    end

    test "update_media/2 with valid data updates the media" do
      media = media_fixture()
      assert {:ok, %Media{} = media} = Feeds.update_media(media, @update_attrs)
      assert media.type == "some updated type"
      assert media.url == "some updated url"
    end

    test "update_media/2 with invalid data returns error changeset" do
      media = media_fixture()
      assert {:error, %Ecto.Changeset{}} = Feeds.update_media(media, @invalid_attrs)
      assert media == Feeds.get_media!(media.id)
    end

    test "delete_media/1 deletes the media" do
      media = media_fixture()
      assert {:ok, %Media{}} = Feeds.delete_media(media)
      assert_raise Ecto.NoResultsError, fn -> Feeds.get_media!(media.id) end
    end

    test "change_media/1 returns a media changeset" do
      media = media_fixture()
      assert %Ecto.Changeset{} = Feeds.change_media(media)
    end
  end
end
