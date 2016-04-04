defmodule Cogctl.Actions.Roles.Grant do
  use Cogctl.Action, "roles grant"

  def option_spec do
    [{:role, :undefined, :undefined, {:string, :undefined}, 'Role name (required)'},
     {:user_to_grant, :undefined, 'user', {:string, :undefined}, 'Username of user to grant role'},
     {:group_to_grant, :undefined, 'group', {:string, :undefined}, 'Name of group to grant role'}]
  end

  def run(options, _args, _config, endpoint) do
    role = :proplists.get_value(:role, options)
    user_to_grant = :proplists.get_value(:user_to_grant, options)
    group_to_grant = :proplists.get_value(:group_to_grant, options)

    with_authentication(endpoint,
                        &do_grant(&1, role, user_to_grant, group_to_grant))
  end

  defp do_grant(_endpoint, :undefined, _user_to_grant, _group_to_grant) do
    display_arguments_error
  end

  defp do_grant(_endpoint, _role, :undefined, :undefined) do
    display_arguments_error
  end

  defp do_grant(endpoint, role, user_to_grant, :undefined) do
    case CogApi.HTTP.Internal.role_grant(endpoint, role, "users", user_to_grant) do
      {:ok, _resp} ->
        display_output("Granted #{role} to #{user_to_grant}")
      {:error, error} ->
        display_error(error["errors"])
    end
  end

  defp do_grant(endpoint, role, :undefined, group_to_grant) do
    group = with {:ok, groups} = CogApi.HTTP.Groups.index(endpoint), 
      do: Enum.find(groups, fn(group) -> group.name == group_to_grant end)

    grant_role = with {:ok, roles} = CogApi.HTTP.Roles.index(endpoint),
      do: Enum.find(roles, fn(r) -> r.name == role end)

    case CogApi.HTTP.Roles.grant(endpoint, grant_role, group) do
      {:ok, _resp} ->
        display_output("Granted #{role} to #{group_to_grant}")
      {:error, error} ->
        display_error(error["errors"])
    end
  end

  defp do_grant(_endpoint, _role, _user_to_grant, _group_to_grant) do
    display_arguments_error
  end
end
