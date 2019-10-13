defmodule AgregatWeb.ItemControllerTest do
  use AgregatWeb.ConnCase

  alias Agregat.Feeds

  @create_attrs %{content: "some content", date: ~N[2010-04-17 14:00:00], favorite: true, guid: "some guid", orig_feed_title: "some orig_feed_title", read: true, title: "some title", url: "some url"}
  @update_attrs %{content: "some updated content", date: ~N[2011-05-18 15:01:01], favorite: false, guid: "some updated guid", orig_feed_title: "some updated orig_feed_title", read: false, title: "some updated title", url: "some updated url"}
  @invalid_attrs %{content: nil, date: nil, favorite: nil, guid: nil, orig_feed_title: nil, read: nil, title: nil, url: nil}

  def fixture(:item) do
    {:ok, item} = Feeds.create_item(@create_attrs)
    item
  end

  describe "index" do
    test "lists all items", %{conn: conn} do
      conn = get(conn, Routes.item_path(conn, :index))
      assert html_response(conn, 200) =~ "Listing Items"
    end
  end

  defp create_item(_) do
    item = fixture(:item)
    {:ok, item: item}
  end
end
