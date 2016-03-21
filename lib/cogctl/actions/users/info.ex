defmodule Cogctl.Actions.Users.Info do
  use Cogctl.Action, "users info"
  alias Cogctl.Table

  def option_spec do
    [{:user, :undefined, :undefined, {:string, :undefined}, 'User username (required)'}]
  end

  def run(options, _args, _config, client) do
    with_authentication(client,
                        &do_info(&1, :proplists.get_value(:user, options)))
  end

  defp do_info(_client, :undefined) do
    display_arguments_error
  end

  defp do_info(client, user_username) do
    case CogApi.user_show(client, user_username) do
      {:ok, resp} ->
        user = resp["user"]

        user = for {title, attr} <- [{"ID", "id"}, {"Username", "username"}, {"First Name", "first_name"}, {"Last Name", "last_name"}, {"Email", "email_address"}] do
          [title, user[attr]]
        end

        display_output(Table.format(user, false))
      {:error, error} ->
        display_error(error["error"])
    end
  end
end
