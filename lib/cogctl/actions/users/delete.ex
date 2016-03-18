defmodule Cogctl.Actions.Users.Delete do
  use Cogctl.Action, "users delete"

  def option_spec do
    [{:user, :undefined, :undefined, {:string, :undefined}, 'Username'}]
  end

  def run(options, _args, _config, client) do
    with_authentication(client,
                        &do_delete(&1, :proplists.get_value(:user, options)))
  end

  defp do_delete(_client, :undefined) do
    display_arguments_error
  end

  defp do_delete(client, user_username) do
    case CogApi.user_delete(client, user_username) do
      :ok ->
        display_output("Deleted #{user_username}")
      {:error, error} ->
        display_error(error["error"])
    end
  end
end
