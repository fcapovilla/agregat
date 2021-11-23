defmodule AgregatWeb.FeedController do
  use AgregatWeb, :controller

  alias Agregat.Feeds
  alias Agregat.Feeds.Feed

  def new(conn, _params) do
    changeset = Feeds.change_feed(%Feed{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"feed" => feed_params}) do
    user = conn.assigns.current_user
    feed_params = Map.put(feed_params, "user_id", user.id)

    feed_params =
      if feed_params["folder_title"] == "" do
        Map.put(feed_params, "folder_title", "Default")
      else
        feed_params
      end

    case Feeds.create_feed(feed_params) do
      {:ok, feed} ->
        Agregat.Syncer.sync_feed(feed)

        conn
        |> put_flash(:info, "Feed created successfully.")
        |> redirect(to: Routes.live_path(conn, AgregatWeb.AppLive))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def edit(conn, %{"id" => id}) do
    feed = Feeds.get_feed!(id)
    changeset = Feeds.change_feed(feed)
    render(conn, "edit.html", feed: feed, changeset: changeset)
  end

  def update(conn, %{"id" => id, "feed" => feed_params}) do
    feed = Feeds.get_feed!(id)

    case Feeds.update_feed(feed, feed_params) do
      {:ok, feed} ->
        Agregat.Syncer.sync_feed(feed)

        conn
        |> put_flash(:info, "Feed updated successfully.")
        |> redirect(to: Routes.live_path(conn, AgregatWeb.AppLive))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", feed: feed, changeset: changeset)
    end
  end
end
