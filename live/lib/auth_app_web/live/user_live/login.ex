defmodule AuthAppWeb.UserLive.Login do
  use AuthAppWeb, :live_view

  alias AuthApp.Accounts
  alias AuthAppWeb.UserAuth

  on_mount {UserAuth, :mount_current_user}

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm">
      <.header class="text-center">
        <p :if={!@current_user}>Log in to account</p>
        <p :if={@current_user}>Log in to re-authenticate</p>
        <:subtitle :if={!@current_user}>
          Don't have an account?
          <.link navigate={~p"/users/register"} class="font-semibold text-brand hover:underline">
            Sign up
          </.link>
          for an account now.
        </:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="login_form"
        action={~p"/users/log-in"}
        phx-submit="submit"
        phx-trigger-action={@trigger_submit}
      >
        <.input
          disabled={!!@current_user}
          field={@form[:email]}
          type="email"
          label="Email"
          autocomplete="username"
          required
        />
        <input
          :if={!!@current_user}
          type="hidden"
          name={@form[:email].name}
          value={@current_user.email}
        />
        <.input
          :if={@mode == :password}
          field={@form[:password]}
          type="password"
          label="Password"
          autocomplete="current-password"
        />
        <.input
          :if={!@current_user}
          field={@form[:remember_me]}
          type="checkbox"
          label="Keep me logged in"
        />
        <.button class="w-full">
          <%= if @mode == :magic do %>
            Log in with email
          <% else %>
            Log in
          <% end %>
          <span aria-hidden="true">→</span>
        </.button>
        <p :if={@mode == :magic} class="text-sm">
          You can <.link patch={~p"/users/log-in?mode=password"} class="underline" phx-no-format>log in with password</.link> instead.
        </p>
        <p :if={@mode == :password} class="text-sm">
          Forgot your password? (<.link
            patch={~p"/users/log-in?mode=email"}
            class="underline"
            phx-no-format
          >log in with email</.link>)
          to get back into your account and set a new one.
        </p>
        <div :if={@mode == :magic and local_mail_adapter?()} class="mt-8 p-4 border text-center">
          <p>You are running the local mail adapter.</p>
          <p>
            To see sent emails, visit <.link href="/dev/mailbox" class="underline">the mailbox page</.link>.
          </p>
        </div>
      </.simple_form>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    email =
      Phoenix.Flash.get(socket.assigns.flash, :email) ||
        get_in(socket.assigns, [:current_user, Access.key(:email)])

    form = to_form(%{"email" => email}, as: "user")

    {:ok, assign(socket, form: form, trigger_submit: false)}
  end

  def handle_params(params, _uri, socket) do
    mode =
      case params do
        %{"mode" => "magic"} -> :magic
        %{"mode" => "password"} -> :password
        _ -> :magic
      end

    {:noreply, assign(socket, :mode, mode)}
  end

  def handle_event("submit", %{"user" => %{"email" => email} = user_params}, socket) do
    case socket.assigns.mode do
      :magic ->
        extra_params = Map.take(user_params, ["remember_me"])

        if user = Accounts.get_user_by_email(email) do
          Accounts.deliver_login_instructions(
            user,
            &url(~p"/users/log-in/#{&1}?#{extra_params}")
          )
        end

        info =
          "If your email is in our system, you will receive instructions for logging in shortly."

        {:noreply,
         socket
         |> put_flash(:info, info)
         |> push_navigate(to: ~p"/users/log-in")}

      :password ->
        # directly submit to the controller
        {:noreply, assign(socket, :trigger_submit, true)}
    end
  end

  defp local_mail_adapter? do
    Application.get_env(:auth_app, AuthApp.Mailer)[:adapter] == Swoosh.Adapters.Local
  end
end
