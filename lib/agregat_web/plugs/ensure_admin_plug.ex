defmodule AgregatWeb.EnsureAdminPlug do
  @moduledoc """
  This plug ensures that a user is an admin.

  ## Example

      plug MyAppWeb.EnsureAdminPlug
  """
  import Plug.Conn, only: [halt: 1]

  alias AgregatWeb.Router.Helpers, as: Routes
  alias Phoenix.Controller
  alias Plug.Conn

  @doc false
  @spec init(any()) :: any()
  def init(config), do: config

  @doc false
  @spec call(Conn.t(), atom()) :: Conn.t()
  def call(conn, _) do
    conn.assigns.current_user
    |> is_admin?()
    |> maybe_halt(conn)
  end

  defp is_admin?(%{admin: true}), do: true
  defp is_admin?(_), do: false

  defp maybe_halt(true, conn), do: conn
  defp maybe_halt(_any, conn) do
    conn
    |> Controller.put_flash(:error, "Unauthorized access")
    |> Controller.redirect(to: Routes.live_path(conn, AgregatWeb.AppLive))
    |> halt()
  end
end
