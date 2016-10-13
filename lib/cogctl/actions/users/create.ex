defmodule Cogctl.Actions.Users.Create do
  use Cogctl.Action, "users create"
  alias Cogctl.Table

  # Whitelisted options passed as params to api endpoint
  @params [:first_name, :last_name, :email_address, :username, :password]

  def option_spec do
    [{:first_name, :undefined, 'first-name', {:string, :undefined}, 'First name'},
     {:last_name, :undefined, 'last-name', {:string, :undefined}, 'Last name'},
     {:email_address, :undefined, 'email', :string, 'Email address (required)'},
     {:username, :undefined, 'username', :string, 'Username (required)'},
     {:password, :undefined, 'password', :string, 'Password (required)'}]
  end

  def run(options, _args, _config, endpoint) do
    params = convert_to_params(options, [:first_name, :last_name, :email_address, :username, :password])
    with_authentication(endpoint, &do_create(&1, params))
  end

  defp do_create(endpoint, params) do
    case CogApi.HTTP.Users.create(endpoint, params) do
      {:ok, user} ->
        user_attrs = for {title, attr} <- [{"ID", :id}, {"Username", :username}, {"First Name", :first_name}, {"Last Name", :last_name}, {"Email", :email_address}] do
          generate_table_row(title, Map.fetch!(user, attr))
        end

        Table.format(user_attrs, false) |> display_output
      {:error, error} ->
        display_error(error)
    end
  end

  defp generate_table_row(title, nil), do: [title, ""]
  defp generate_table_row(title, attr), do: [title, attr]
end
