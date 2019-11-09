defmodule Agregat.FaviconFetcher do
  require Logger

  alias Agregat.Feeds

  def fetch(url, force \\ false) do
    uri = URI.parse(url)
    host = uri.scheme <> "://" <> uri.authority
    case Feeds.list_favicons(%{host: host}) do
      [favicon|_] ->
        if force do
          case fetch_favicon(uri) do
            {:ok, data} -> Feeds.update_favicon(favicon, data)
            _ -> {:ok, favicon}
          end
        else
          {:ok, favicon}
        end
      _ ->
        case fetch_favicon(uri) do
          {:ok, data} -> Feeds.create_favicon(data)
          {:error, e} -> {:error, e}
        end
    end
  end

  defp fetch_favicon(uri) do
    host = uri.scheme <> "://" <> uri.authority
    case download_favicon(host) do
      {:ok, data} -> {:ok, %{data | host: host}}
      _ ->
        www_host = uri.scheme <> "://www." <> uri.authority
        case download_favicon(www_host) do
          {:ok, data} -> {:ok, %{data | host: host}}
          {:error, e} -> {:error, e}
        end
    end
  end

  defp download_favicon(host) do
    url = host <> "/favicon.ico"
    case Agregat.HttpClient.get(url) do
      {:ok, response} ->
        headers = Enum.into(response.headers, %{})
        if headers["content-type"] =~ ~r/^image\/.*icon$/ do
          {:ok, %{data: Base.encode64(response.body), host: host}}
        else
          {:error, "Invalid content type for " <> url <> " : " <> headers["content-type"]}
        end
      _ -> {:error, "Error fetching " <> url}
    end
  end
end
