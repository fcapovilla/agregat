defmodule Agregat.Syncer do
  require Logger

  alias Agregat.Feeds.Feed
  alias Agregat.Feeds.Item
  alias Agregat.Repo

  import Ecto.Query, only: [from: 2]

  def sync_all do
    Repo.all(from f in Feed, where: datetime_add(f.last_sync, f.update_frequency, "minute") < ^DateTime.utc_now)
    |> Task.async_stream(&sync_feed/1, max_concurrency: 5, timeout: 30_000)
    |> Enum.to_list()

    # Broadcast updated folder list
    folders = Agregat.Feeds.list_folders()
    Phoenix.PubSub.broadcast(Agregat.PubSub, "folders", %{folders: folders})
  end

  # Update items for the feed in parameter.
  def sync_feed(feed) do
    with {:ok, data} <- Agregat.HttpClient.get(feed.url),
         {:ok, parsed_feed, _} <- FeederEx.parse(data.body)
    do
      update_feed(feed, parsed_feed)
    else
      {:error, code} ->
        # Try to get a string representation of the error
        code = case code do
          str when is_bitstring(str) -> str
          %{message: message} -> message
          %{__struct__: code} -> to_string(code)
          _ -> "Unknown error"
        end

        Logger.error "Error syncing " <> feed.url <> " : " <> code
        Agregat.Feeds.update_feed(feed, %{sync_status: code})
      _ ->
        Logger.error "Error syncing " <> feed.url
        Agregat.Feeds.update_feed(feed, %{sync_status: "Unknown error."})
    end
  end

  # Recalculate the sync frequency of all feeds using automatic frequency calculation
  # The frequency goes from one every 30 minutes (30) to once every week (10080)
  def recalculate_sync_frequencies do
    Repo.all(from f in Feed, where: f.auto_frequency == true)
    |> Enum.each(fn(feed) ->
      Repo.transaction fn ->
        month_count = Repo.one(
          from i in Item,
          select: count(i.id),
          where: i.feed_id == ^feed.id
          and i.date > ago(30, "day")
        )

        frequency = if month_count < 360, do: round(30/(month_count+1)*6*60), else: 30
        IO.puts frequency
        Agregat.Feeds.update_feed(feed, %{update_frequency: frequency})
      end
    end)
  end

  # Update items for the feed in parameter using the parsed_feed.
  defp update_feed(feed, parsed_feed) do
    items = Enum.map(parsed_feed.entries, fn(entry) ->
      %{
        feed_id: feed.id,
        user_id: feed.user_id,
        title: entry.title || entry.link || entry.id,
        url: entry.link || entry.id,
        content: entry.summary,
        date: Agregat.DateParser.parse(entry.updated) || DateTime.utc_now,
        guid: entry.id || entry.link,
        medias: (if entry.enclosure, do: [%{url: entry.enclosure.url, type: entry.enclosure.type}], else: [])
      }
    end)

    # Update feed items
    Repo.transaction fn ->
      existing_items = Repo.all(
        from i in Item,
        where: i.guid in ^Enum.map(items, &(&1.guid))
               and i.user_id == ^feed.user_id
               and i.feed_id == ^feed.id,
        preload: [:medias]
      )

      updated_items = Enum.map(items, fn(item) ->
        existing = Enum.find(existing_items, &(&1.guid == item.guid))
        if existing do
          changeset = Item.changeset(existing, item)
          if changeset.changes != %{} do
            Repo.update!(changeset)
          else
            false
          end
        else
          {:ok, item} = Agregat.Feeds.create_item(item)
          item
        end
      end)
      |> Enum.filter(&(&1))

      updated_feed = Agregat.Feeds.update_feed(feed, %{
        title: (if parsed_feed.title == "", do: feed.title, else: parsed_feed.title),
        last_sync: DateTime.utc_now,
        sync_status: ""
      })

      if updated_items != [] do
        # Update feed data
        {:ok, updated_feed} = Agregat.Feeds.update_unread_count(feed)

        # Broadcast changes
        updated_items = Repo.preload(updated_items, [:feed, :medias])
        data = %{feed: updated_feed, items: updated_items}
        Phoenix.PubSub.broadcast(Agregat.PubSub, "feed-#{updated_feed.id}", data)
        Phoenix.PubSub.broadcast(Agregat.PubSub, "folder-#{updated_feed.folder_id}", data)
        Phoenix.PubSub.broadcast(Agregat.PubSub, "items", data)

        updated_feed
      else
        updated_feed
      end
    end
  end
end
