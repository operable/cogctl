defmodule Cogctl.Actions.Roles.Delete do
  use Cogctl.Action, "roles delete"

  def option_spec do
    [{:role, :undefined, :undefined, :string, 'Role name (required)'}]
  end

  def run(options, _args, _config, endpoint) do
    with_authentication(endpoint,
                        &do_delete(&1, :proplists.get_value(:role, options)))
  end

  defp do_delete(_endpoint, :undefined) do
    display_arguments_error
  end

  defp do_delete(endpoint, role_name) do
    case CogApi.HTTP.Internal.role_delete(endpoint, role_name) do
      :ok ->
        display_output("Deleted #{role_name}")
      {:error, error} ->
        display_error(error["errors"])
    end
  end
end
