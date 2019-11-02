defmodule Agregat.Feeds do
  @moduledoc """
  The Feeds context.
  """

  import Ecto.Query, warn: false
  alias Agregat.Repo

  alias Agregat.Users.User
  alias Agregat.Feeds.Favicon
  alias Agregat.Feeds.Feed
  alias Agregat.Feeds.Folder
  alias Agregat.Feeds.Item
  alias Agregat.Feeds.Media

  @doc """
  Returns the list of favicons.

  ## Examples

      iex> list_favicons()
      [%Favicon{}, ...]

  """
  def list_favicons(filters \\ %{}) do
    Favicon
    |> filter_by(filters)
    |> Repo.all()
  end

  @doc """
  Returns the first favicon matching the filters in parameter.
  If the favicon doesn't exist, it is created.

  ## Examples

      iex> first_or_create_favicon!(%{url: "Test"})
      %Favicon{}

  """
  def first_or_create_favicon!(filters \\ %{}) do
    case list_favicons(filters) do
      [favicon | _] -> favicon
      _ ->
        {:ok, favicon} = create_favicon(filters)
        favicon
    end
  end

  @doc """
  Gets a single favicon.

  Raises `Ecto.NoResultsError` if the Favicon does not exist.

  ## Examples

      iex> get_favicon!(123)
      %Favicon{}

      iex> get_favicon!(456)
      ** (Ecto.NoResultsError)

  """
  def get_favicon!(id, filters \\ %{}) do
    Favicon
    |> filter_by(filters)
    |> Repo.get!(id)
  end

  @doc """
  Creates a favicon.

  ## Examples

      iex> create_favicon(%{field: value})
      {:ok, %Favicon{}}

      iex> create_favicon(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_favicon(attrs \\ %{}) do
    %Favicon{}
    |> Favicon.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a favicon.

  ## Examples

      iex> update_favicon(favicon, %{field: new_value})
      {:ok, %Favicon{}}

      iex> update_favicon(favicon, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_favicon(%Favicon{} = favicon, attrs) do
    favicon
    |> Favicon.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Favicon.

  ## Examples

      iex> delete_favicon(favicon)
      {:ok, %Favicon{}}

      iex> delete_favicon(favicon)
      {:error, %Ecto.Changeset{}}

  """
  def delete_favicon(%Favicon{} = favicon) do
    Repo.delete(favicon)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking favicon changes.

  ## Examples

      iex> change_favicon(favicon)
      %Ecto.Changeset{source: %Favicon{}}

  """
  def change_favicon(%Favicon{} = favicon) do
    Favicon.changeset(favicon, %{})
  end

  @doc """
  Returns the list of folders.

  ## Examples

      iex> list_folders()
      [%Folder{}, ...]

  """
  def list_folders(filters \\ %{}) do
    Folder
    |> filter_by(filters)
    |> order_by(:position)
    |> preload(feeds: ^(from f in Feed, order_by: f.position))
    |> Repo.all()
    |> count_unread()
  end

  @doc """
  Returns the first folder matching the filters in parameter.
  If the folder doesn't exist, it is created.

  ## Examples

      iex> first_or_create_folder!(%{title: "Test"})
      %Folder{}

  """
  def first_or_create_folder!(filters \\ %{}) do
    case list_folders(filters) do
      [folder | _] -> folder
      _ ->
        {:ok, folder} = create_folder(filters)
        folder
    end
  end

  @doc """
  Gets a single folder.

  Raises `Ecto.NoResultsError` if the Folder does not exist.

  ## Examples

      iex> get_folder!(123)
      %Folder{}

      iex> get_folder!(456)
      ** (Ecto.NoResultsError)

  """
  def get_folder!(id, filters \\ %{}) do
    Folder
    |> filter_by(filters)
    |> preload(:feeds)
    |> Repo.get!(id)
    |> count_unread()
  end

  defp count_unread(folders) when is_list(folders) do
    Enum.map(folders, &count_unread/1)
  end

  defp count_unread(folder) do
    %{folder | unread_count: Enum.reduce(folder.feeds, 0, &((&1.unread_count || 0) + &2))}
  end

  @doc """
  Creates a folder.

  ## Examples

      iex> create_folder(%{field: value})
      {:ok, %Folder{}}

      iex> create_folder(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_folder(attrs \\ %{}) do
    %Folder{}
    |> Folder.changeset(attrs)
    |> Repo.insert()
    |> broadcast_folder()
  end

  @doc """
  Updates a folder.

  ## Examples

      iex> update_folder(folder, %{field: new_value})
      {:ok, %Folder{}}

      iex> update_folder(folder, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_folder(%Folder{} = folder, attrs) do
    folder
    |> Folder.changeset(attrs)
    |> Repo.update()
    |> broadcast_folder()
  end

  def broadcast_folder({:ok, %Folder{} = folder}) do
    folders = list_folders(user_id: folder.user_id)
    Phoenix.PubSub.broadcast(Agregat.PubSub, "folders", %{folders: folders, user_id: folder.user_id})
    {:ok, folder}
  end
  def broadcast_folder(any), do: any

  @doc """
  Deletes a Folder.

  ## Examples

      iex> delete_folder(folder)
      {:ok, %Folder{}}

      iex> delete_folder(folder)
      {:error, %Ecto.Changeset{}}

  """
  def delete_folder(%Folder{} = folder) do
    Repo.delete(folder)
    |> broadcast_folder()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking folder changes.

  ## Examples

      iex> change_folder(folder)
      %Ecto.Changeset{source: %Folder{}}

  """
  def change_folder(%Folder{} = folder) do
    Folder.changeset(folder, %{})
  end

  @doc """
  Returns the list of feeds.

  ## Examples

      iex> list_feeds()
      [%Feed{}, ...]

  """
  def list_feeds(filters \\ %{}) do
    Feed
    |> filter_by(filters)
    |> preload(:folder)
    |> Repo.all()
    |> set_feed_virtuals()
  end

  @doc """
  Returns the first feed matching the filters in parameter.
  If the feed doesn't exist, it is created.

  ## Examples

      iex> first_or_create_feed!(%{url: "Test"})
      %Feed{}

  """
  def first_or_create_feed!(filters \\ %{}) do
    case list_feeds(filters) do
      [feed | _] -> feed
      _ ->
        {:ok, feed} = create_feed(filters)
        feed
    end
  end

  @doc """
  Gets a single feed.

  Raises `Ecto.NoResultsError` if the Feed does not exist.

  ## Examples

      iex> get_feed!(123)
      %Feed{}

      iex> get_feed!(456)
      ** (Ecto.NoResultsError)

  """
  def get_feed!(id, filters \\ %{}) do
    Feed
    |> filter_by(filters)
    |> preload(:folder)
    |> Repo.get!(id)
    |> set_feed_virtuals()
  end

  @doc """
  Creates a feed.

  ## Examples

      iex> create_feed(%{field: value})
      {:ok, %Feed{}}

      iex> create_feed(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_feed(attrs \\ %{}) do
    %Feed{}
    |> Feed.changeset(attrs)
    |> Repo.insert()
    |> broadcast_feed()
  end

  @doc """
  Updates a feed.

  ## Examples

      iex> update_feed(feed, %{field: new_value})
      {:ok, %Feed{}}

      iex> update_feed(feed, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_feed(%Feed{} = feed, attrs) do
    feed
    |> Feed.changeset(attrs)
    |> Repo.update()
    |> broadcast_feed()
  end

  def broadcast_feed({:ok, %Feed{} = feed}) do
    folders = list_folders(user_id: feed.user_id)
    Phoenix.PubSub.broadcast(Agregat.PubSub, "folders", %{folders: folders, user_id: feed.user_id})
    Phoenix.PubSub.broadcast(Agregat.PubSub, "feeds", %{feeds: [feed], user_id: feed.user_id})
    {:ok, feed}
  end
  def broadcast_feed(any), do: any

  defp set_feed_virtuals([] = feeds), do: Enum.map(feeds, &set_feed_virtuals/1)
  defp set_feed_virtuals(%Feed{} = feed), do: %{feed | folder_title: feed.folder.title}

  @doc """
  Deletes a Feed.

  ## Examples

      iex> delete_feed(feed)
      {:ok, %Feed{}}

      iex> delete_feed(feed)
      {:error, %Ecto.Changeset{}}

  """
  def delete_feed(%Feed{} = feed) do
    Repo.delete(feed)
    |> broadcast_feed()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking feed changes.

  ## Examples

      iex> change_feed(feed)
      %Ecto.Changeset{source: %Feed{}}

  """
  def change_feed(%Feed{} = feed) do
    Feed.changeset(feed, %{})
  end

  @doc """
  Returns the list of items.

  ## Examples

      iex> list_items()
      [%Item{}, ...]

  """
  def list_items(filters \\ %{}) do
    Item
    |> filter_by(filters)
    |> Repo.all()
  end

  @doc """
  Returns the first item matching the filters in parameter.
  If the item doesn't exist, it is created.

  ## Examples

      iex> first_or_create_item!(%{url: "Test"})
      %Item{}

  """
  def first_or_create_item!(filters \\ %{}) do
    case list_items(filters) do
      [item | _] -> item
      _ ->
        {:ok, item} = create_item(filters)
        item
    end
  end

  @doc """
  Gets a single item.

  Raises `Ecto.NoResultsError` if the Item does not exist.

  ## Examples

      iex> get_item!(123)
      %Item{}

      iex> get_item!(456)
      ** (Ecto.NoResultsError)

  """
  def get_item!(id, filters \\ %{}) do
    Item
    |> filter_by(filters)
    |> preload([:feed, :medias])
    |> Repo.get!(id)
  end

  @doc """
  Creates a item.

  ## Examples

      iex> create_item(%{field: value})
      {:ok, %Item{}}

      iex> create_item(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_item(attrs \\ %{}) do
    %Item{}
    |> Item.changeset(attrs)
    |> Repo.insert()
    |> update_unread_count()
    |> broadcast_item()
  end

  @doc """
  Updates a item.

  ## Examples

      iex> update_item(item, %{field: new_value})
      {:ok, %Item{}}

      iex> update_item(item, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_item(%Item{} = item, attrs) do
    item
    |> Item.changeset(attrs)
    |> Repo.update()
    |> update_unread_count()
    |> broadcast_item()
  end

  def broadcast_item({:ok, %Item{} = item}) do
    item = Repo.preload(item, [:feed, :medias])
    Phoenix.PubSub.broadcast(Agregat.PubSub, "items", %{items: [item], user_id: item.user_id})
    Phoenix.PubSub.broadcast(Agregat.PubSub, "feed-#{item.feed.id}", %{items: [item], user_id: item.user_id})
    Phoenix.PubSub.broadcast(Agregat.PubSub, "folder-#{item.feed.folder_id}", %{items: [item], user_id: item.user_id})
    {:ok, item}
  end
  def broadcast_item(any), do: any

  def update_unread_count({:ok, data}), do: update_unread_count(data)
  def update_unread_count(%Item{} = item) do
    get_feed!(item.feed_id)
    |> update_unread_count()
    {:ok, item}
  end
  def update_unread_count(%Feed{} = feed) do
    Repo.transaction fn ->
      count = Repo.one(from i in Item, select: count(i.id), where: i.feed_id == ^feed.id and i.read == false)
      update_feed(feed, %{unread_count: count})
    end
  end
  def update_unread_count(any), do: any

  @doc """
  Deletes a Item.

  ## Examples

      iex> delete_item(item)
      {:ok, %Item{}}

      iex> delete_item(item)
      {:error, %Ecto.Changeset{}}

  """
  def delete_item(%Item{} = item) do
    Repo.delete(item)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking item changes.

  ## Examples

      iex> change_item(item)
      %Ecto.Changeset{source: %Item{}}

  """
  def change_item(%Item{} = item) do
    Item.changeset(item, %{})
  end

  @doc """
  Returns the list of medias.

  ## Examples

      iex> list_medias()
      [%Media{}, ...]

  """
  def list_medias(filters \\ %{}) do
    Media
    |> filter_by(filters)
    |> Repo.all()
  end

  @doc """
  Returns the first media matching the filters in parameter.
  If the media doesn't exist, it is created.

  ## Examples

      iex> first_or_create_media!(%{url: "Test"})
      %Media{}

  """
  def first_or_create_media!(filters \\ %{}) do
    case list_medias(filters) do
      [media | _] -> media
      _ ->
        {:ok, media} = create_media(filters)
        media
    end
  end

  @doc """
  Gets a single media.

  Raises `Ecto.NoResultsError` if the Media does not exist.

  ## Examples

      iex> get_media!(123)
      %Media{}

      iex> get_media!(456)
      ** (Ecto.NoResultsError)

  """
  def get_media!(id, filters \\ %{}) do
    Media
    |> filter_by(filters)
    |> Repo.get!(id)
  end

  @doc """
  Creates a media.

  ## Examples

      iex> create_media(%{field: value})
      {:ok, %Media{}}

      iex> create_media(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_media(attrs \\ %{}) do
    %Media{}
    |> Media.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a media.

  ## Examples

      iex> update_media(media, %{field: new_value})
      {:ok, %Media{}}

      iex> update_media(media, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_media(%Media{} = media, attrs) do
    media
    |> Media.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Media.

  ## Examples

      iex> delete_media(media)
      {:ok, %Media{}}

      iex> delete_media(media)
      {:error, %Ecto.Changeset{}}

  """
  def delete_media(%Media{} = media) do
    Repo.delete(media)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking media changes.

  ## Examples

      iex> change_media(media)
      %Ecto.Changeset{source: %Media{}}

  """
  def change_media(%Media{} = media) do
    Media.changeset(media, %{})
  end

  def filter_by(query, filters) do
    Enum.reduce(filters, query, fn ({key, value}, query) -> (from x in query, where: field(x, ^key) == ^value) end)
  end

  def paginate(query, page, per_page \\ 50) do
    from i in query, limit: ^per_page, offset: ^((page - 1) * per_page)
  end
end
