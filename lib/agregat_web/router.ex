defmodule AgregatWeb.Router do
  use AgregatWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", AgregatWeb do
    pipe_through :browser

    get "/", PageController, :index
    get "/folder/:id/toggle", FolderController, :toggle
    resources "/folders", FolderController
  end

  # Other scopes may use custom stacks.
  # scope "/api", AgregatWeb do
  #   pipe_through :api
  # end
end
