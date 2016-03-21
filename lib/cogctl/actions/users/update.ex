defmodule Cogctl.Actions.Users.Update do
  use Cogctl.Action, "users update"
  alias Cogctl.Table

  def option_spec do
    [{:user, :undefined, :undefined, {:string, :undefined}, 'Username (required)'},
     {:first_name, :undefined, 'first-name', {:string, :undefined}, 'First name'},
     {:last_name, :undefined, 'last-name', {:string, :undefined}, 'Last name'},
     {:email_address, :undefined, 'email', {:string, :undefined}, 'Email address'},
     {:username, :undefined, 'username', {:string, :undefined}, 'Username'},
     {:password, :undefined, 'password', {:string, :undefined}, 'Password'}]
  end

  def run(options, _args, _config, client) do
    params = convert_to_params(options, [first_name: :optional,
                                         last_name: :optional,
                                         email_address: :optional,
                                         username: :optional,
                                         password: :optional])

    with_authentication(client,
                        &do_update(&1, :proplists.get_value(:user, options), params))
  end

  defp do_update(_client, _user_username, :error) do
    display_arguments_error
  end

  defp do_update(client, user_username, {:ok, params}) do
    case CogApi.user_update(client, user_username, %{user: params}) do
      {:ok, resp} ->
        user = resp["user"]
        username = user["username"]

        user_attrs = for {title, attr} <- [{"ID", "id"}, {"Username", "username"}, {"First Name", "first_name"}, {"Last Name", "last_name"}, {"Email", "email_address"}] do
          [title, user[attr]]
        end

        display_output("""
        Updated #{username}

        #{Table.format(user_attrs, false)}
        """ |> String.rstrip)
      {:error, error} ->
        display_error(error["error"])
    end
  end
end
