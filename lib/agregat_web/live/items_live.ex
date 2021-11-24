defmodule AgregatWeb.ItemsLive do
  use AgregatWeb, :live_view

  import Ecto.Query, only: [from: 2]

  alias Agregat.Feeds

  def mount(_params, %{"params" => params} = session, socket) do
    socket = assign_defaults(session, socket)

    if connected?(socket) do
      case params do
        %{"folder_id" => folder_id} ->
          Phoenix.PubSub.subscribe(Agregat.PubSub, "folder-#{folder_id}")

        %{"feed_id" => feed_id} ->
          Phoenix.PubSub.subscribe(Agregat.PubSub, "feed-#{feed_id}")

        _ ->
          Phoenix.PubSub.subscribe(Agregat.PubSub, "items")
      end
    end

    {:ok,
     assign(socket, page: 1, params: params, item_ids: [])
     |> fetch_items(), temporary_assigns: [item_ids: []]}
  end

  def handle_event("toggle-favorite-" <> item_id, _, socket) do
    item = Feeds.get_item!(String.to_integer(item_id), user_id: socket.assigns.current_user.id)

    case Feeds.update_item(item, %{favorite: !item.favorite}) do
      {:ok, item} ->
        {:noreply, assign(socket, items: [item])}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def handle_event("toggle-read-" <> item_id, _, socket) do
    item = Feeds.get_item!(String.to_integer(item_id), user_id: socket.assigns.current_user.id)

    case Feeds.update_item(item, %{read: !item.read}) do
      {:ok, item} ->
        {:noreply, assign(socket, items: [item])}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def handle_event("load-more", _, %{assigns: %{page: page}} = socket) do
    {:noreply, assign(socket, page: page + 1) |> fetch_items()}
  end

  def handle_event("keydown", _, socket) do
    {:noreply, socket}
  end

  defp fetch_items(%{assigns: %{params: params, page: page}} = socket) do
    item_ids =
      from(i in Feeds.Item, select: i.id)
      |> filter(params)
      |> sort(params)
      |> Feeds.filter_by(user_id: socket.assigns.current_user.id)
      |> Feeds.paginate(page)
      |> Agregat.Repo.all()

    assign(socket, item_ids: item_ids)
  end

  defp filter(query, params) do
    Enum.reduce(params, query, fn {key, value}, query ->
      case key do
        "favorite" ->
          from i in query, where: i.favorite == ^if(value == "true", do: true, else: false)

        "read" ->
          from i in query, where: i.read == ^if(value == "true", do: true, else: false)

        "folder_id" ->
          from i in query, left_join: f in assoc(i, :feed), where: f.folder_id == ^value

        "feed_id" ->
          from i in query, where: i.feed_id == ^value

        _ ->
          query
      end
    end)
  end

  defp sort(query, _params) do
    from i in query, order_by: [desc: :date]
  end

  def handle_info(%{items: items, user_id: user_id}, socket) do
    if user_id == socket.assigns.current_user.id do
      items =
        if socket.assigns.params["read"] == "false" do
          Enum.filter(items, &(!&1.read))
        else
          items
        end

      for item <- items do
        send_update(AgregatWeb.ItemComponent, id: item.id, item: item)
      end

      item_ids = Enum.map(items, & &1.id)
      {:noreply, assign(socket, item_ids: item_ids)}
    else
      {:noreply, socket}
    end
  end
end
