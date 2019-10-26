defmodule AgregatWeb.Router do
  use AgregatWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug Phoenix.LiveView.Flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", AgregatWeb do
    pipe_through :browser

    live "/", AppLive
    resources "/folder", FolderController
    resources "/feed", FeedController
  end

  # Other scopes may use custom stacks.
  # scope "/api", AgregatWeb do
  #   pipe_through :api
  # end
end
