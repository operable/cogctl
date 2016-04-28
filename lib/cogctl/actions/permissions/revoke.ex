defmodule Cogctl.Actions.Permissions.Revoke do
  use Cogctl.Action, "permissions revoke"

  def option_spec do
    [{:permission, :undefined, :undefined, :string, 'Permission name (required)'},
     {:role_to_revoke, :undefined, 'role', {:string, :undefined}, 'Role to revoke permission from'}]
  end

  def run(options, _args, _config, endpoint) do
    permission = :proplists.get_value(:permission, options)
    role_to_revoke = :proplists.get_value(:role_to_revoke, options)

    with_authentication(endpoint, &do_revoke(&1, permission, role_to_revoke))
  end

  defp do_revoke(_endpoint, :undefined, _), do: display_arguments_error
  defp do_revoke(_endpoint, _, :undefined), do: display_arguments_error

  defp do_revoke(endpoint, permission, role_to_revoke) do
    case CogApi.HTTP.Internal.permission_revoke(endpoint, permission, "roles", role_to_revoke) do
      {:ok, _resp} ->
        display_output("Revoked #{permission} from #{role_to_revoke}")
      {:error, error} ->
        display_error(error["errors"])
    end
  end

end
