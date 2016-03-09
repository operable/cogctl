defmodule Cogctl.Actions.Users.Delete do
  use Cogctl.Action, "users delete"

  def option_spec do
    [{:user, :undefined, :undefined, {:string, :undefined}, 'Username'}]
  end

  def run(options, _args, _config, client) do
    case CogApi.authenticate(client) do
      {:ok, client} ->
        do_delete(client, :proplists.get_value(:user, options))
      {:error, error} ->
        display_error(error["error"])
    end
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
