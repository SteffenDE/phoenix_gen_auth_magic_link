defmodule AuthAppWeb.UserSessionHTML do
  use AuthAppWeb, :html

  embed_templates "user_session_html/*"

  defp local_mail_adapter? do
    Application.get_env(:auth_app, AuthApp.Mailer)[:adapter] == Swoosh.Adapters.Local
  end
end
