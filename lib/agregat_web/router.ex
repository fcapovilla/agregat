defmodule AgregatWeb.Router do
  use AgregatWeb, :router
  use Pow.Phoenix.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug Phoenix.LiveView.Flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :protected do
    plug Pow.Plug.RequireAuthenticated,
    error_handler: Pow.Phoenix.PlugErrorHandler
  end

  pipeline :admin do
    plug AgregatWeb.EnsureAdminPlug
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/" do
    pipe_through :browser

    pow_session_routes()
    get "/logout", Pow.Phoenix.SessionController, :delete
  end

  scope "/", AgregatWeb do
    pipe_through [:browser, :protected, :admin]
    resources "/users", UserController
    get "/favicons/refresh", FaviconController, :refresh
  end

  scope "/", AgregatWeb do
    pipe_through [:browser, :protected]

    live "/", AppLive, session: [:agregat_auth]
    resources "/folder", FolderController
    resources "/feed", FeedController
    get "/favicons/:id", FaviconController, :show
  end
end
