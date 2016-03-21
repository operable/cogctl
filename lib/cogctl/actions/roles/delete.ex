defmodule Cogctl.Actions.Roles.Delete do
  use Cogctl.Action, "roles delete"

  def option_spec do
    [{:role, :undefined, :undefined, {:string, :undefined}, 'Role name (required)'}]
  end

  def run(options, _args, _config, client) do
    with_authentication(client,
                        &do_delete(&1, :proplists.get_value(:role, options)))
  end

  defp do_delete(_client, :undefined) do
    display_arguments_error
  end

  defp do_delete(client, role_name) do
    case CogApi.role_delete(client, role_name) do
      :ok ->
        display_output("Deleted #{role_name}")
      {:error, error} ->
        display_error(error["error"])
    end
  end
end
