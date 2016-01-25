defmodule Cogctl.Actions.Users.Update do
  use Cogctl.Action, "users update"
  alias Cogctl.CogApi
  alias Cogctl.Table

  # Whitelisted options passed as params to api client
  @params [:first_name, :last_name, :email_address, :username, :password]

  def option_spec do
    [{:user, :undefined, :undefined, {:string, :undefined}, 'Username'},
     {:first_name, :undefined, 'first-name', {:string, :undefined}, 'First name'},
     {:last_name, :undefined, 'last-name', {:string, :undefined}, 'Last name'},
     {:email_address, :undefined, 'email', {:string, :undefined}, 'Email address'},
     {:username, :undefined, 'username', {:string, :undefined}, 'Username'},
     {:password, :undefined, 'password', {:string, :undefined}, 'Password'}]
  end

  def run(options, _args, _config, profile) do
    client = CogApi.new_client(profile)
    case CogApi.authenticate(client) do
      {:ok, client} ->
        do_update(client, :proplists.get_value(:user, options), options)
      {:error, error} ->
        IO.puts "#{error["error"]}"
    end
  end

  defp do_update(client, user_username, options) do
    params = make_user_params(options)
    case CogApi.user_update(client, user_username, %{user: params}) do
      {:ok, resp} ->
        user = resp["user"]
        username = user["username"]

        user_attrs = for {title, attr} <- [{"ID", "id"}, {"Username", "username"}, {"First Name", "first_name"}, {"Last Name", "last_name"}, {"Email", "email_address"}] do
          [title, user[attr]]
        end

        IO.puts("Updated #{username}")
        IO.puts("")
        IO.puts(Table.format(user_attrs))

        :ok
      {:error, resp} ->
        {:error, resp}
    end
  end

  defp make_user_params(options) do
    options
    |> Keyword.take(@params)
    |> Enum.reject(&match?({_, :undefined}, &1))
    |> Enum.into(%{})
  end
end
