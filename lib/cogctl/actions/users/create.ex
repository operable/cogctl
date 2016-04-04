defmodule Cogctl.Actions.Users.Create do
  use Cogctl.Action, "users create"
  alias Cogctl.Table

  # Whitelisted options passed as params to api endpoint
  @params [:first_name, :last_name, :email_address, :username, :password]

  def option_spec do
    [{:first_name, :undefined, 'first-name', {:string, :undefined}, 'First name'},
     {:last_name, :undefined, 'last-name', {:string, :undefined}, 'Last name'},
     {:email_address, :undefined, 'email', {:string, :undefined}, 'Email address (required)'},
     {:username, :undefined, 'username', {:string, :undefined}, 'Username (required)'},
     {:password, :undefined, 'password', {:string, :undefined}, 'Password (required)'}]
  end

  def run(options, _args, _config, endpoint) do
    params = convert_to_params(options, [first_name: :optional,
                                         last_name: :optional,
                                         email_address: :required,
                                         username: :required,
                                         password: :required])

    with_authentication(endpoint, &do_create(&1, params))
  end

  defp do_create(_endpoint, :error) do
    display_arguments_error
  end

  defp do_create(endpoint, {:ok, params}) do
    case CogApi.HTTP.Users.create(endpoint, params) do
      {:ok, user} ->
        username = user.username

        user_attrs = for {title, attr} <- [{"ID", :id}, {"Username", :username}, {"First Name", :first_name}, {"Last Name", :last_name}, {"Email", :email_address}] do
          generate_table_row(title, Map.fetch!(user, attr))
        end

        display_output("""
        Created #{username}

        #{Table.format(user_attrs, false)}
        """ |> String.rstrip)
      {:error, error} ->
        display_error(error["errors"])
    end
  end

  defp generate_table_row(title, nil), do: [title, ""]
  defp generate_table_row(title, attr), do: [title, attr]
end
