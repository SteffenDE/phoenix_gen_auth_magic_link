defmodule AuthAppWeb.UserSessionController do
  use AuthAppWeb, :controller

  alias AuthApp.Accounts
  alias AuthAppWeb.UserAuth

  def new(conn, params) do
    mode =
      case params do
        %{"mode" => "magic"} -> :magic
        %{"mode" => "password"} -> :password
        _ -> :magic
      end

    render(conn, :new, mode: mode, error_message: nil)
  end

  # magic link request
  def create(conn, %{"_action" => "magic", "user" => %{"email" => email} = user_params}) do
    extra_params = Map.take(user_params, ["remember_me"])

    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_login_instructions(
        user,
        &url(~p"/users/log-in/#{&1}?#{extra_params}")
      )
    end

    info =
      "If your email is in our system, you will receive instructions for logging in shortly."

    conn
    |> put_flash(:info, info)
    |> redirect(to: ~p"/users/log-in")
  end

  # magic link sign in
  def create(conn, %{"user" => %{"token" => token} = user_params} = params) do
    info =
      case params do
        %{"_action" => "confirmed"} -> "Account confirmed successfully!"
        _ -> "Welcome back!"
      end

    case Accounts.magic_link_sign_in(token) do
      {:ok, user, _tokens_to_disconnect} ->
        conn
        |> put_flash(:info, info)
        |> UserAuth.log_in_user(user, user_params)

      {:error, :not_found} ->
        conn
        |> put_flash(:error, "The link is invalid or it has expired.")
        |> redirect(to: ~p"/users/log-in")
    end
  end

  # email + password sign in
  def create(conn, %{"user" => user_params}) do
    %{"email" => email, "password" => password} = user_params

    if user = Accounts.get_user_by_email_and_password(email, password) do
      conn
      |> put_flash(:info, "Welcome back!")
      |> UserAuth.log_in_user(user, user_params)
    else
      # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
      render(conn, :new, mode: :password, error_message: "Invalid email or password")
    end
  end

  def confirm(conn, %{"token" => token} = params) do
    if user = Accounts.get_user_by_magic_link_token(token) do
      form = Phoenix.Component.to_form(params, as: "user")

      conn
      |> assign(:user, user)
      |> assign(:form, form)
      |> render(:confirm)
    else
      conn
      |> put_flash(:error, "Magic link is invalid or it has expired.")
      |> redirect(to: ~p"/users/log-in")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> UserAuth.log_out_user()
  end
end
