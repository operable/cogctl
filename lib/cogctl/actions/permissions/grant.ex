defmodule Cogctl.Actions.Permissions.Grant do
  use Cogctl.Action, "permissions grant"

  def option_spec do
    [{:permission, :undefined, :undefined, {:string, :undefined}, 'Permission name (required)'},
     {:role, :undefined, 'role', {:string, :undefined}, 'Role name (required)'}]
  end

  def run(options, _args, _config, endpoint) do
    permission = :proplists.get_value(:permission, options)
    role = :proplists.get_value(:role, options)

    with_authentication(endpoint, &do_grant(&1, permission, role))
  end

  defp do_grant(_endpoint, :undefined, _), do: display_arguments_error
  defp do_grant(_endpoint, _, :undefined), do: display_arguments_error

  defp do_grant(endpoint, permission, role) do
    case CogApi.HTTP.Internal.permission_grant(endpoint, permission, "roles", role) do
      {:ok, _resp} ->
        display_output("Granted #{permission} to #{role}")
      {:error, error} ->
        display_error(error["errors"])
    end
  end

end
