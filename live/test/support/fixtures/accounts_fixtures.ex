defmodule AuthApp.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `AuthApp.Accounts` context.
  """

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def valid_user_password, do: "hello world!"

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_user_email()
    })
  end

  def unconfirmed_user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> AuthApp.Accounts.register_user()

    user
  end

  def user_fixture(attrs \\ %{}) do
    user = unconfirmed_user_fixture(attrs)

    token =
      extract_user_token(fn url ->
        AuthApp.Accounts.deliver_login_instructions(user, url)
      end)

    {:ok, user, _tokens_to_expire} = AuthApp.Accounts.magic_link_login(token)

    user
  end

  def set_password(user) do
    {:ok, user, _tokens_to_expire} =
      AuthApp.Accounts.update_user_password(user, %{password: valid_user_password()})

    user
  end

  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end
end
