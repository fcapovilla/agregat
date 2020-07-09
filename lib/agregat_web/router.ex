defmodule AgregatWeb.Router do
  use AgregatWeb, :router
  use Pow.Phoenix.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :fetch_live_flash
    plug :put_root_layout, {AgregatWeb.LayoutView, :root}
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

    live "/", AppLive
    resources "/folder", FolderController
    resources "/feed", FeedController
    get "/favicons/:id", FaviconController, :show
  end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: AgregatWeb.Telemetry
    end
  end
end
