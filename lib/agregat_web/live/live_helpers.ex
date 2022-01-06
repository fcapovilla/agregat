defmodule AgregatWeb.LiveHelpers do
  import Phoenix.LiveView

  alias AgregatWeb.Router.Helpers, as: Routes

  def assign_defaults(session, socket) do
    if session["locale"] do
      Gettext.put_locale(AgregatWeb.Gettext, session["locale"])
    end

    socket =
      assign_new(socket, :current_user, fn ->
        find_current_user(session)
      end)

    case socket.assigns.current_user do
      %Agregat.Users.User{} ->
        socket

      _other ->
        socket
        |> put_flash(:error, "You must log in to access this page.")
        |> redirect(to: Routes.user_session_path(socket, :new))
    end
  end

  defp find_current_user(session) do
    with user_token when not is_nil(user_token) <- session["user_token"],
         %Agregat.Users.User{} = user <- Agregat.Users.get_user_by_session_token(user_token),
         do: user
  end
end
