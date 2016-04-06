defmodule Cogctl.Actions.Roles.Revoke do
  use Cogctl.Action, "roles revoke"

  def option_spec do
    [{:role, :undefined, :undefined, {:string, :undefined}, 'Role name (required)'},
     {:group_to_revoke, :undefined, 'group', {:string, :undefined}, 'Name of group to revoke role from'}]
  end

  def run(options, _args, _config, endpoint) do
    role = :proplists.get_value(:role, options)
    group_to_revoke = :proplists.get_value(:group_to_revoke, options)
    with_authentication(endpoint, &do_revoke(&1, role, group_to_revoke))
  end

  defp do_revoke(_endpoint, :undefined, _), do: display_arguments_error
  defp do_revoke(_endpoint, _, :undefined), do: display_arguments_error

  defp do_revoke(endpoint, role, group_to_revoke) do
    group = with {:ok, groups} = CogApi.HTTP.Groups.index(endpoint), 
      do: Enum.find(groups, fn(group) -> group.name == group_to_revoke end)

    revoke_role = with {:ok, roles} = CogApi.HTTP.Roles.index(endpoint),
      do: Enum.find(roles, fn(r) -> r.name == role end)

    case CogApi.HTTP.Roles.revoke(endpoint, revoke_role, group) do
      {:ok, _resp} ->
        display_output("Revoked #{role} from #{group_to_revoke}")
      {:error, error} ->
        display_error(error["errors"])
    end
  end

end
