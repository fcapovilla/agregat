defmodule AgregatWeb.SetLocalePlug do
  @moduledoc """
  This plug sets the current locale using the connected user's configuration.
  If no user is connected, use browser headers.

  ## Example

      plug AgregatWeb.SetLocalePlug
  """
  alias Phoenix.Controller

  @locales Gettext.known_locales(AgregatWeb.Gettext)

  def init(config), do: config

  def call(conn, _) do
    case locale_from_user(conn) || locale_from_header(conn) do
      nil ->
        conn

      locale ->
        Gettext.put_locale(AgregatWeb.Gettext, locale)
        conn |> Plug.Conn.put_session(:locale, locale)
    end
  end

  defp locale_from_user(conn) do
    if conn.assigns.current_user do
      conn.assigns.current_user.locale
    else
      nil
    end
  end

  # Following lines taken from the set_locale plug: https://github.com/smeevil/set_locale
  defp locale_from_header(conn) do
    conn
    |> extract_accept_language
    |> Enum.find(nil, fn accepted_locale -> Enum.member?(@locales, accepted_locale) end)
  end

  defp extract_accept_language(conn) do
    case Plug.Conn.get_req_header(conn, "accept-language") do
      [value | _] ->
        value
        |> String.split(",")
        |> Enum.map(&parse_language_option/1)
        |> Enum.sort(&(&1.quality > &2.quality))
        |> Enum.map(& &1.tag)
        |> Enum.reject(&is_nil/1)
        |> ensure_language_fallbacks()

      _ ->
        []
    end
  end

  defp parse_language_option(string) do
    captures = Regex.named_captures(~r/^\s?(?<tag>[\w\-]+)(?:;q=(?<quality>[\d\.]+))?$/i, string)

    quality =
      case Float.parse(captures["quality"] || "1.0") do
        {val, _} -> val
        _ -> 1.0
      end

    %{tag: captures["tag"], quality: quality}
  end

  defp ensure_language_fallbacks(tags) do
    Enum.flat_map(tags, fn tag ->
      [language | _] = String.split(tag, "-")
      if Enum.member?(tags, language), do: [tag], else: [tag, language]
    end)
  end
end
