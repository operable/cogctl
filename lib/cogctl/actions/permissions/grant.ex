defmodule Cogctl.Actions.Permissions.Grant do
  use Cogctl.Action, "permissions grant"

  def option_spec do
    [{:permission, :undefined, :undefined, {:string, :undefined}, 'Permission name (required)'},
     {:user_to_grant, :undefined, 'user', {:string, :undefined}, 'Username of user to grant permission'},
     {:group_to_grant, :undefined, 'group', {:string, :undefined}, 'Name of group to grant permission'},
     {:role_to_grant, :undefined, 'role', {:string, :undefined}, 'Role to grant permission'}]
  end

  def run(options, _args, _config, endpoint) do
    permission = :proplists.get_value(:permission, options)
    user_to_grant = :proplists.get_value(:user_to_grant, options)
    group_to_grant = :proplists.get_value(:group_to_grant, options)
    role_to_grant = :proplists.get_value(:role_to_grant, options)

    with_authentication(endpoint,
                        &do_grant(&1, permission, user_to_grant, group_to_grant, role_to_grant))
  end

  defp do_grant(_endpoint, :undefined, _user_to_grant, _group_to_grant, _role_to_grant) do
    display_arguments_error
  end

  defp do_grant(_endpoint, _permission, :undefined, :undefined, :undefined) do
    display_arguments_error
  end

  defp do_grant(endpoint, permission, user_to_grant, :undefined, :undefined) do
    case CogApi.HTTP.Old.permission_grant(endpoint, permission, "users", user_to_grant) do
      {:ok, _resp} ->
        display_output("Granted #{permission} to #{user_to_grant}")
      {:error, error} ->
        display_error(error["errors"])
    end
  end

  defp do_grant(endpoint, permission, :undefined, group_to_grant, :undefined) do
    case CogApi.HTTP.Old.permission_grant(endpoint, permission, "groups", group_to_grant) do
      {:ok, _resp} ->
        display_output("Granted #{permission} to #{group_to_grant}")
      {:error, error} ->
        display_error(error["errors"])
    end
  end

  defp do_grant(endpoint, permission, :undefined, :undefined, role_to_grant) do
    case CogApi.HTTP.Old.permission_grant(endpoint, permission, "roles", role_to_grant) do
      {:ok, _resp} ->
        display_output("Granted #{permission} to #{role_to_grant}")
      {:error, error} ->
        display_error(error["errors"])
    end
  end

  defp do_grant(_endpoint, _permission, _user_to_grant, _group_to_grant, _role_to_grant) do
    display_arguments_error
  end
end
