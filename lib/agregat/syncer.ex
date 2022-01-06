defmodule Agregat.Syncer do
  require Logger

  alias Agregat.Feeds.Feed
  alias Agregat.Feeds.Item
  alias Agregat.Repo

  import Ecto.Query, only: [from: 2]

  @doc """
  Synchronize all feeds if their update_frequency was reached.
  All feeds are synchronized in parallel.
  """
  def sync_all do
    Repo.all(
      from f in Feed,
        where: datetime_add(f.last_sync, f.update_frequency, "minute") < ^DateTime.utc_now()
    )
    |> Task.async_stream(&sync_feed/1, max_concurrency: 5, timeout: 30_000)
    |> Enum.to_list()
  end

  @doc """
  Synchronize items for the feed in parameter.
  """
  def sync_feed(feed) do
    with {:ok, data} <- Agregat.HttpClient.get(feed.url),
         {:ok, parsed_feed, _} <- parse_feed(feed, data.body) do
      update_feed(feed, parsed_feed)
    else
      {:error, code} ->
        # Try to get a string representation of the error
        code =
          case code do
            str when is_bitstring(str) -> str
            %{message: message} -> message
            %{__struct__: code} -> to_string(code)
            _ -> "Unknown error"
          end

        Logger.error("Error syncing " <> feed.url <> " : " <> code)
        Agregat.Feeds.update_feed(feed, %{sync_status: code})

      _ ->
        Logger.error("Error syncing " <> feed.url)
        Agregat.Feeds.update_feed(feed, %{sync_status: "Unknown error."})
    end
  end

  @doc """
  Parse a feed.
  XML is parsed with FeederEx. HTML is parsed with Floki.
  """
  def parse_feed(%Feed{is_html: false}, data), do: FeederEx.parse(data)

  def parse_feed(feed, data) do
    feed_uri = URI.parse(feed.url)
    feed_host = feed_uri.scheme <> "://" <> feed_uri.authority

    {:ok, document} = Floki.parse_document(data)
    elements = Floki.find(document, feed.parsing_settings["container"])

    entries =
      Enum.map(elements, fn element ->
        link =
          Floki.find(element, feed.parsing_settings["url"])
          |> Floki.attribute("href")
          |> Enum.at(0)

        link = if link =~ ~r/^http/, do: link, else: feed_host <> link

        %{
          title: Floki.find(element, feed.parsing_settings["title"]) |> Floki.text(),
          link: link,
          id: link,
          summary: Floki.find(element, feed.parsing_settings["content"]) |> Floki.raw_html(),
          updated: Floki.find(element, feed.parsing_settings["date"]) |> Floki.text(),
          enclosure: nil
        }
      end)

    {:ok,
     %{
       title: Floki.find(document, "head title") |> Floki.text(),
       entries: entries
     }, nil}
  end

  @doc """
  Recalculate the sync frequency of all feeds using automatic frequency calculation
  The frequency goes from one every 30 minutes (30) to once every week (10080)
  """
  def recalculate_sync_frequencies do
    Repo.all(from f in Feed, where: f.auto_frequency == true)
    |> Enum.each(fn feed ->
      Repo.transaction(fn ->
        month_count =
          Repo.one(
            from i in Item,
              select: count(i.id),
              where:
                i.feed_id == ^feed.id and
                  i.date > ago(30, "day")
          )

        frequency = if month_count < 360, do: round(30 / (month_count + 1) * 6 * 60), else: 30
        Agregat.Feeds.update_feed(feed, %{update_frequency: frequency})
      end)
    end)
  end

  # Update items for the feed in parameter using the parsed_feed.
  defp update_feed(feed, parsed_feed) do
    items =
      Enum.map(parsed_feed.entries, fn entry ->
        date =
          case DateTimeParser.parse(entry.updated) do
            {:ok, date} -> date
            {:error, _} -> DateTime.utc_now()
          end

        %{
          feed_id: feed.id,
          user_id: feed.user_id,
          title: entry.title || entry.link || entry.id,
          url: entry.link || entry.id,
          content: entry.summary,
          date: date,
          guid: entry.id || entry.link,
          medias:
            if(entry.enclosure,
              do: [%{url: entry.enclosure.url, type: entry.enclosure.type}],
              else: []
            )
        }
      end)

    Agregat.Feeds.sync_feed_items(feed, items)

    Agregat.Feeds.update_feed(feed, %{
      title: if(parsed_feed.title == "", do: feed.title, else: parsed_feed.title),
      last_sync: DateTime.utc_now(),
      sync_status: ""
    })
  end
end
