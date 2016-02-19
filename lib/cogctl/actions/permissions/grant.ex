defmodule Cogctl.Actions.Permissions.Grant do
  use Cogctl.Action, "permissions grant"
  alias Cogctl.CogApi

  def option_spec do
    [{:permission, :undefined, :undefined, {:string, :undefined}, 'Permission name (required)'},
     {:user_to_grant, :undefined, 'user', {:string, :undefined}, 'Username of user to grant permission'},
     {:group_to_grant, :undefined, 'group', {:string, :undefined}, 'Name of group to grant permission'},
     {:role_to_grant, :undeinfed, 'role', {:string, :undefined}, 'Role to grant permission'}]
  end

  def run(options, _args, _config, profile) do
    client = CogApi.new_client(profile)
    case CogApi.authenticate(client) do
      {:ok, client} ->
        permission = :proplists.get_value(:permission, options)
        user_to_grant = :proplists.get_value(:user_to_grant, options)
        group_to_grant = :proplists.get_value(:group_to_grant, options)
        role_to_grant = :proplists.get_value(:role_to_grant, options)
        do_grant(client, permission, user_to_grant, group_to_grant, role_to_grant)
      {:error, error} ->
        display_error(error["error"])
    end
  end

  defp do_grant(_client, :undefined, _user_to_grant, _group_to_grant, _role_to_grant) do
    display_arguments_error
  end

  defp do_grant(_client, _permission, :undefined, :undefined, :undefined) do
    display_arguments_error
  end

  defp do_grant(client, permission, user_to_grant, :undefined, :undefined) do
    case CogApi.permission_grant(client, permission, "users", user_to_grant) do
      {:ok, _resp} ->
        display_output("Granted #{permission} to #{user_to_grant}")
      {:error, error} ->
        display_error(error["error"])
    end
  end

  defp do_grant(client, permission, :undefined, group_to_grant, :undefined) do
    case CogApi.permission_grant(client, permission, "groups", group_to_grant) do
      {:ok, _resp} ->
        display_output("Granted #{permission} to #{group_to_grant}")
      {:error, error} ->
        display_error(error["error"])
    end
  end

  defp do_grant(client, permission, :undefined, :undefined, role_to_grant) do
    case CogApi.permission_grant(client, permission, "roles", role_to_grant) do
      {:ok, _resp} ->
        display_output("Granted #{permission} to #{role_to_grant}")
      {:error, error} ->
        display_error(error["error"])
    end
  end

  defp do_grant(_client, _permission, _user_to_grant, _group_to_grant, _role_to_grant) do
    display_arguments_error
  end
end
