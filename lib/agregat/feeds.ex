defmodule Agregat.Feeds do
  @moduledoc """
  The Feeds context.
  """

  import Ecto.Query, warn: false
  alias Agregat.Repo
  alias Agregat.Feeds.Favicon
  alias Agregat.Feeds.Feed
  alias Agregat.Feeds.Folder
  alias Agregat.Feeds.Item
  alias Agregat.Feeds.Media

  ### FAVICONS ###

  @doc """
  Returns the list of favicons.
  """
  def list_favicons(filters \\ %{}) do
    Favicon
    |> filter_by(filters)
    |> Repo.all()
  end

  @doc """
  Returns the first favicon matching the filters in parameter.
  If the favicon doesn't exist, it is created.
  """
  def first_or_create_favicon!(filters \\ %{}) do
    case list_favicons(filters) do
      [favicon | _] ->
        favicon

      _ ->
        {:ok, favicon} = create_favicon(filters)
        favicon
    end
  end

  @doc """
  Gets a single favicon.
  Raises `Ecto.NoResultsError` if the Favicon does not exist.
  """
  def get_favicon!(id, filters \\ %{}) do
    Favicon
    |> filter_by(filters)
    |> Repo.get!(id)
  end

  @doc """
  Creates a favicon.
  """
  def create_favicon(attrs \\ %{}) do
    %Favicon{}
    |> Favicon.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a favicon.
  """
  def update_favicon(%Favicon{} = favicon, attrs) do
    favicon
    |> Favicon.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Favicon.
  """
  def delete_favicon(%Favicon{} = favicon) do
    Repo.delete(favicon)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking favicon changes.
  """
  def change_favicon(%Favicon{} = favicon) do
    Favicon.changeset(favicon, %{})
  end

  ### FOLDERS ###

  @doc """
  Returns the list of folders.
  """
  def list_folders(filters \\ %{}) do
    from(f in Folder,
      left_join: feeds in assoc(f, :feeds),
      preload: [feeds: feeds],
      order_by: [asc: f.position, asc: feeds.position]
    )
    |> filter_by(filters)
    |> Repo.all()
    |> count_unread()
  end

  @doc """
  Returns the first folder matching the filters in parameter.
  If the folder doesn't exist, it is created.
  """
  def first_or_create_folder!(filters \\ %{}) do
    case list_folders(filters) do
      [folder | _] ->
        folder

      _ ->
        {:ok, folder} = create_folder(filters)
        folder
    end
  end

  @doc """
  Gets a single folder.
  Raises `Ecto.NoResultsError` if the Folder does not exist.
  """
  def get_folder!(id, filters \\ %{}) do
    from(f in Folder,
      left_join: feeds in assoc(f, :feeds),
      preload: [feeds: feeds],
      order_by: [asc: feeds.position]
    )
    |> filter_by(filters)
    |> Repo.get!(id)
    |> count_unread()
  end

  @doc """
  Creates a folder.
  """
  def create_folder(attrs \\ %{}, opts \\ %{}) do
    %Folder{}
    |> Folder.changeset(attrs)
    |> Repo.insert()
    |> broadcast_folder(opts)
  end

  @doc """
  Updates a folder.
  """
  def update_folder(%Folder{} = folder, attrs, opts \\ %{}) do
    changeset = Folder.changeset(folder, attrs)
    Map.put(opts, :broadcast, changeset.changes != %{})
    Repo.update(changeset) |> broadcast_folder(opts)
  end

  @doc """
  Deletes a Folder.
  """
  def delete_folder(%Folder{} = folder) do
    Repo.delete(folder)
    |> broadcast_folder()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking folder changes.
  """
  def change_folder(%Folder{} = folder) do
    Folder.changeset(folder, %{})
  end

  @doc """
  Moves a folder after another.
  """
  def move_folder(%Folder{} = folder, %Folder{} = dest_folder) do
    list =
      list_folders(user_id: folder.user_id)
      |> List.delete(folder)

    index = Enum.find_index(list, &(&1.id == dest_folder.id))

    list
    |> List.insert_at(index + 1, folder)
    |> Enum.with_index(fn folder, index ->
      update_folder(folder, %{position: index})
    end)
  end

  defp count_unread(folders) when is_list(folders) do
    Enum.map(folders, &count_unread/1)
  end

  defp count_unread(folder) do
    %{folder | unread_count: Enum.reduce(folder.feeds, 0, &((&1.unread_count || 0) + &2))}
  end

  defp broadcast_folder(any, opts \\ %{})
  defp broadcast_folder(any, %{broadcast: false}), do: any
  defp broadcast_folder({:ok, %Folder{} = folder}, _), do: {:ok, broadcast_folder(folder)}
  defp broadcast_folder(%Folder{} = folder, _), do: broadcast_folders([folder]) |> hd()
  defp broadcast_folder(any, _), do: any

  defp broadcast_folders([%Folder{} | _] = folders) do
    folders
    |> Enum.group_by(& &1.user_id)
    |> Enum.each(fn {user_id, folders} ->
      # For now, broadcast the whole folder list
      # TODO: Optimise to only return the folders that changed
      folders = list_folders(user_id: user_id)

      Phoenix.PubSub.broadcast(Agregat.PubSub, "folders", %{
        folders: folders,
        user_id: user_id
      })
    end)

    folders
  end

  defp broadcast_folders(any), do: any

  ### FEEDS ###

  @doc """
  Returns the list of feeds.
  """
  def list_feeds(filters \\ %{}) do
    from(f in Feed,
      left_join: folder in assoc(f, :folder),
      preload: [folder: folder],
      order_by: [asc: folder.position, asc: f.position]
    )
    |> filter_by(filters)
    |> Repo.all()
    |> set_feed_virtuals()
  end

  @doc """
  Returns the first feed matching the filters in parameter.
  If the feed doesn't exist, it is created.
  """
  def first_or_create_feed!(filters \\ %{}) do
    case list_feeds(filters) do
      [feed | _] ->
        feed

      _ ->
        {:ok, feed} = create_feed(filters)
        feed
    end
  end

  @doc """
  Gets a single feed.
  Raises `Ecto.NoResultsError` if the Feed does not exist.
  """
  def get_feed!(id, filters \\ %{}) do
    from(f in Feed, left_join: folder in assoc(f, :folder), preload: [folder: folder])
    |> filter_by(filters)
    |> Repo.get!(id)
    |> set_feed_virtuals()
  end

  @doc """
  Creates a feed.
  """
  def create_feed(attrs \\ %{}) do
    %Feed{}
    |> Feed.changeset(attrs)
    |> fetch_feed_favicon()
    |> Repo.insert()
    |> broadcast_feed()
  end

  @doc """
  Updates a feed.
  """
  def update_feed(%Feed{} = feed, attrs, opts \\ %{}) do
    changeset = Feed.changeset(feed, attrs)
    Map.put(opts, :broadcast, changeset.changes != %{})
    Repo.update(changeset) |> broadcast_feed()
  end

  @doc """
  Deletes a feed.
  """
  def delete_feed(%Feed{} = feed) do
    Repo.delete(feed)
    |> broadcast_feed()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking feed changes.
  """
  def change_feed(%Feed{} = feed) do
    Feed.changeset(feed, %{})
  end

  @doc """
  Moves a feed in the first position of a folder.
  """
  def move_feed(%Feed{} = feed, %Folder{} = dest_folder) do
    list =
      list_feeds(folder_id: dest_folder.id)
      |> List.delete(feed)

    list
    |> List.insert_at(0, feed)
    |> Enum.with_index(fn feed, index ->
      update_feed(feed, %{position: index, folder_id: dest_folder.id})
    end)
  end

  @doc """
  Moves a feed after another.
  """
  def move_feed(%Feed{} = feed, %Feed{} = dest_feed) do
    list =
      list_feeds(folder_id: dest_feed.folder_id)
      |> List.delete(feed)

    index = Enum.find_index(list, &(&1.id == dest_feed.id))

    list
    |> List.insert_at(index + 1, feed)
    |> Enum.with_index(fn feed, index ->
      update_feed(feed, %{position: index, folder_id: dest_feed.folder_id})
    end)
  end

  @doc """
  Synchronizes a feed's items, detecting existing items using their guid.
  Missing items will be created.
  """
  def sync_feed_items(feed, items) do
    Repo.transaction(fn ->
      existing_items =
        Repo.all(
          from i in Item,
            where:
              i.guid in ^Enum.map(items, & &1.guid) and
                i.user_id == ^feed.user_id and
                i.feed_id == ^feed.id,
            preload: [:medias]
        )

      updated_items =
        Enum.map(items, fn item ->
          existing = Enum.find(existing_items, &(&1.guid == item.guid))

          {:ok, item} =
            if existing do
              changeset = Item.changeset(existing, item)

              if changeset.changes != %{} do
                Repo.update(changeset)
              else
                {:ok, false}
              end
            else
              Item.changeset(%Item{}, item) |> Repo.insert()
            end

          item
        end)
        |> Enum.filter(& &1)

      Agregat.Feeds.broadcast_items(updated_items)

      update_unread_count(feed)
    end)
  end

  defp fetch_feed_favicon(changeset) do
    case Agregat.FaviconFetcher.fetch(Ecto.Changeset.get_field(changeset, :url)) do
      {:ok, favicon} -> Ecto.Changeset.put_change(changeset, :favicon_id, favicon.id)
      {:error, _} -> changeset
    end
  end

  defp broadcast_feed(any, opts \\ %{})
  defp broadcast_feed(any, %{broadcast: false}), do: any
  defp broadcast_feed({:ok, %Feed{} = feed}, _), do: {:ok, broadcast_feed(feed)}
  defp broadcast_feed(%Feed{} = feed, _), do: broadcast_feeds([feed]) |> hd()
  defp broadcast_feed(any, _), do: any

  defp broadcast_feeds([%Feed{} | _] = feeds) do
    feeds
    |> Enum.group_by(& &1.user_id)
    |> Enum.each(fn {user_id, feeds} ->
      Phoenix.PubSub.broadcast(Agregat.PubSub, "feeds", %{feeds: [feeds], user_id: user_id})
    end)

    feeds
  end

  defp broadcast_feeds(any), do: any

  defp set_feed_virtuals([%Feed{} | _] = feeds), do: Enum.map(feeds, &set_feed_virtuals/1)
  defp set_feed_virtuals(%Feed{} = feed), do: %{feed | folder_title: feed.folder.title}

  ### ITEMS ###

  @doc """
  Returns the list of items.
  """
  def list_items(filters \\ %{}, opts \\ %{}) do
    {folder_id, filters} = Map.pop(filters, "folder_id")

    from(i in Item,
      left_join: m in assoc(i, :medias),
      left_join: f in assoc(i, :feed),
      order_by: [desc: :date],
      preload: [feed: f, medias: m]
    )
    |> filter_by(filters)
    |> filter_items_by_folder_id(folder_id)
    |> paginate(Map.get(opts, :page))
    |> Repo.all()
  end

  @doc """
  Returns the first item matching the filters in parameter.
  If the item doesn't exist, it is created.
  """
  def first_or_create_item!(filters \\ %{}) do
    case list_items(filters) do
      [item | _] ->
        item

      _ ->
        {:ok, item} = create_item(filters)
        item
    end
  end

  @doc """
  Gets a single item.
  Raises `Ecto.NoResultsError` if the Item does not exist.
  """
  def get_item!(id, filters \\ %{}) do
    from(i in Item,
      left_join: m in assoc(i, :medias),
      left_join: f in assoc(i, :feed),
      preload: [feed: f, medias: m]
    )
    |> filter_by(filters)
    |> Repo.get!(id)
  end

  @doc """
  Creates a item.
  """
  def create_item(attrs \\ %{}, opts \\ %{}) do
    %Item{}
    |> Item.changeset(attrs)
    |> Repo.insert()
    |> update_unread_count()
    |> broadcast_item(opts)
  end

  @doc """
  Updates a item.
  """
  def update_item(%Item{} = item, attrs, opts \\ %{}) do
    changeset = Item.changeset(item, attrs)
    Map.put(opts, :broadcast, changeset.changes != %{})
    result = Repo.update(changeset)
    Task.start(__MODULE__, :update_unread_count, [result])
    Task.start(__MODULE__, :broadcast_item, [result, opts])
    result
  end

  @doc """
  Updates specific attributes of all items of a folder.
  """
  def update_folder_items(folder_id, attrs) do
    query = from i in Item, join: f in assoc(i, :feed), where: f.folder_id == ^folder_id
    Repo.update_all(query, set: Map.to_list(attrs))

    Repo.all(query)
    |> broadcast_items()

    list_feeds(%{folder_id: folder_id})
    |> update_unread_count()
  end

  @doc """
  Updates specific attributes of all items of a feed.
  """
  def update_feed_items(feed_id, attrs) do
    query = from i in Item, where: i.feed_id == ^feed_id
    Repo.update_all(query, set: Map.to_list(attrs))

    Repo.all(query)
    |> broadcast_items()
    |> hd()
    |> update_unread_count()
  end

  @doc """
  Deletes a Item.
  """
  def delete_item(%Item{} = item) do
    Repo.delete(item)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking item changes.
  """
  def change_item(%Item{} = item) do
    Item.changeset(item, %{})
  end

  @doc false
  def update_unread_count({:ok, data}), do: update_unread_count(data)

  def update_unread_count(%Item{} = item) do
    get_feed!(item.feed_id)
    |> update_unread_count()

    {:ok, item}
  end

  def update_unread_count([%Feed{} | _] = items), do: Enum.map(items, &update_unread_count/1)

  def update_unread_count(%Feed{} = feed) do
    count =
      Repo.one(
        from i in Item, select: count(i.id), where: i.feed_id == ^feed.id and i.read == false
      )

    update_feed(feed, %{unread_count: count})
  end

  def update_unread_count(any), do: any

  @doc false
  def broadcast_item(any, opts \\ %{})
  def broadcast_item(any, %{broadcast: false}), do: any
  def broadcast_item({:ok, %Item{} = item}, _), do: {:ok, broadcast_item(item)}
  def broadcast_item(%Item{} = item, _), do: broadcast_items([item]) |> hd()
  def broadcast_item(any, _), do: any

  def broadcast_items([%Item{} | _] = items) do
    items
    |> Repo.preload([:feed, :medias])
    |> Enum.group_by(& &1.user_id)
    |> Enum.each(fn {user_id, items} ->
      Phoenix.PubSub.broadcast(Agregat.PubSub, "items", %{items: items, user_id: user_id})

      items
      |> Enum.group_by(& &1.feed_id)
      |> Enum.each(fn {feed_id, items} ->
        Phoenix.PubSub.broadcast(Agregat.PubSub, "feed-#{feed_id}", %{
          items: items,
          user_id: user_id
        })
      end)

      items
      |> Enum.group_by(& &1.feed.folder_id)
      |> Enum.each(fn {folder_id, items} ->
        Phoenix.PubSub.broadcast(Agregat.PubSub, "folder-#{folder_id}", %{
          items: items,
          user_id: user_id
        })
      end)
    end)

    items
  end

  def broadcast_items(any), do: any

  defp filter_items_by_folder_id(query, nil), do: query

  defp filter_items_by_folder_id(query, folder_id) do
    from i in query, left_join: f in assoc(i, :feed), where: f.folder_id == ^folder_id
  end

  ### MEDIAS ###

  @doc """
  Returns the list of medias.
  """
  def list_medias(filters \\ %{}) do
    Media
    |> filter_by(filters)
    |> Repo.all()
  end

  @doc """
  Returns the first media matching the filters in parameter.
  If the media doesn't exist, it is created.
  """
  def first_or_create_media!(filters \\ %{}) do
    case list_medias(filters) do
      [media | _] ->
        media

      _ ->
        {:ok, media} = create_media(filters)
        media
    end
  end

  @doc """
  Gets a single media.
  Raises `Ecto.NoResultsError` if the Media does not exist.
  """
  def get_media!(id, filters \\ %{}) do
    Media
    |> filter_by(filters)
    |> Repo.get!(id)
  end

  @doc """
  Creates a media.
  """
  def create_media(attrs \\ %{}) do
    %Media{}
    |> Media.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a media.
  """
  def update_media(%Media{} = media, attrs) do
    media
    |> Media.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Media.
  """
  def delete_media(%Media{} = media) do
    Repo.delete(media)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking media changes.
  """
  def change_media(%Media{} = media) do
    Media.changeset(media, %{})
  end

  ### UTILITY FUNCTIONS ###

  defp filter_by(query, filters) do
    Enum.reduce(filters, query, fn {key, value}, query ->
      value =
        case value do
          "true" -> true
          "false" -> false
          v -> v
        end

      key =
        case key do
          k when is_binary(k) -> String.to_existing_atom(k)
          k -> k
        end

      from x in query, where: field(x, ^key) == ^value
    end)
  end

  defp paginate(query, page, per_page \\ 50) do
    from i in query, limit: ^per_page, offset: ^((page - 1) * per_page)
  end

  defp paginate(query, nil, _), do: query
end
