defmodule Cogctl.Actions.Users.Info do
  use Cogctl.Action, "users info"
  alias Cogctl.CogApi
  alias Cogctl.Table

  def option_spec do
    [{:user, :undefined, :undefined, {:string, :undefined}, 'User username (required)'}]
  end

  def run(options, _args, _config, profile) do
    client = CogApi.new_client(profile)
    case CogApi.authenticate(client) do
      {:ok, client} ->
        do_info(client, :proplists.get_value(:user, options))
      {:error, error} ->
        display_error(error["error"])
    end
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

        display_output(Table.format(user))
      {:error, error} ->
        display_error(error["error"])
    end
  end
end
