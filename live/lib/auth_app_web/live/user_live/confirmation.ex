defmodule AuthAppWeb.UserLive.Confirmation do
  use AuthAppWeb, :live_view

  alias AuthApp.Accounts

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm">
      <.header class="text-center">Welcome {@user.email}</.header>

      <.simple_form
        :if={!@user.confirmed_at}
        for={@form}
        id="confirmation_form"
        phx-submit="submit"
        action={~p"/users/log-in?_action=confirmed"}
        phx-trigger-action={@trigger_submit}
      >
        <input type="hidden" name={@form[:token].name} value={@form[:token].value} />
        <:actions>
          <.button phx-disable-with="Confirming..." class="w-full">Confirm my account</.button>
        </:actions>
      </.simple_form>

      <.simple_form
        :if={@user.confirmed_at}
        for={@form}
        id="login_form"
        phx-submit="submit"
        action={~p"/users/log-in"}
        phx-trigger-action={@trigger_submit}
      >
        <input type="hidden" name={@form[:token].name} value={@form[:token].value} />
        <.input
          :if={!@current_user}
          field={@form[:remember_me]}
          type="checkbox"
          label="Keep me logged in"
        />
        <input
          :if={!!@current_user and @form[:remember_me].value}
          type="hidden"
          name={@form[:remember_me].name}
          value="true"
        />
        <:actions>
          <.button phx-disable-with="Logging in..." class="w-full">Log in</.button>
        </:actions>
      </.simple_form>

      <p :if={!@user.confirmed_at} class="mt-8 p-4 border text-center">
        Tip: If you prefer passwords, you can enable them in the user settings.
      </p>
    </div>
    """
  end

  def mount(%{"token" => token}, session, socket) do
    if user = Accounts.get_user_by_magic_link_token(token) do
      form =
        to_form(%{"token" => token, "remember_me" => session["user_remember_me"]}, as: "user")

      {:ok, assign(socket, user: user, form: form, trigger_submit: false),
       temporary_assigns: [form: nil]}
    else
      {:ok,
       socket
       |> put_flash(:error, "Magic link is invalid or it has expired.")
       |> push_navigate(to: ~p"/users/log-in")}
    end
  end

  def handle_event("submit", %{"user" => params}, socket) do
    {:noreply, assign(socket, form: to_form(params, as: "user"), trigger_submit: true)}
  end
end
