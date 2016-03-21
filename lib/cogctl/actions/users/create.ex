defmodule Cogctl.Actions.Users.Create do
  use Cogctl.Action, "users create"
  alias Cogctl.Table

  # Whitelisted options passed as params to api client
  @params [:first_name, :last_name, :email_address, :username, :password]

  def option_spec do
    [{:first_name, :undefined, 'first-name', {:string, :undefined}, 'First name (required)'},
     {:last_name, :undefined, 'last-name', {:string, :undefined}, 'Last name (required)'},
     {:email_address, :undefined, 'email', {:string, :undefined}, 'Email address (required)'},
     {:username, :undefined, 'username', {:string, :undefined}, 'Username (required)'},
     {:password, :undefined, 'password', {:string, :undefined}, 'Password (required)'}]
  end

  def run(options, _args, _config, client) do
    params = convert_to_params(options, [first_name: :required,
                                         last_name: :required,
                                         email_address: :required,
                                         username: :required,
                                         password: :required])

    with_authentication(client, &do_create(&1, params))
  end

  defp do_create(_client, :error) do
    display_arguments_error
  end

  defp do_create(client, {:ok, params}) do
    case CogApi.user_create(client, %{user: params}) do
      {:ok, resp} ->
        user = resp["user"]
        username = user["username"]

        user_attrs = for {title, attr} <- [{"ID", "id"}, {"Username", "username"}, {"First Name", "first_name"}, {"Last Name", "last_name"}, {"Email", "email_address"}] do
          [title, user[attr]]
        end

        display_output("""
        Created #{username}

        #{Table.format(user_attrs, false)}
        """ |> String.rstrip)
      {:error, error} ->
        display_error(error["error"])
    end
  end
end
