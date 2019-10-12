defmodule AgregatWeb.PageController do
  use AgregatWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
