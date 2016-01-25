defmodule Cogctl.Actions.Permissions.Grant do
  use Cogctl.Action, "permissions grant"
  alias Cogctl.CogApi

  @params [:name]

  def option_spec do
    [{:permission, :undefined, :undefined, {:string, :undefined}, 'Permission name'},
     {:user_to_grant, :undefined, 'user', {:string, :undefined}, 'Username of user to grant permission'},
     {:group_to_grant, :undefined, 'group', {:string, :undefined}, 'Name of group to grant permission'}]
  end

  def run(options, _args, _config, profile) do
    client = CogApi.new_client(profile)
    case CogApi.authenticate(client) do
      {:ok, client} ->
        permission = :proplists.get_value(:permission, options)
        user_to_grant = :proplists.get_value(:user_to_grant, options)
        group_to_grant = :proplists.get_value(:group_to_grant, options)
        do_grant(client, permission, user_to_grant, group_to_grant)
      {:error, error} ->
        IO.puts "#{error["error"]}"
    end
  end

  defp do_grant(client, permission, user_to_grant, :undefined) do
    case CogApi.permission_grant(client, permission, "users", user_to_grant) do
      {:ok, _resp} ->
        IO.puts("Granted #{permission} to #{user_to_grant}")
        :ok
      {:error, resp} ->
        {:error, resp}
    end
  end

  defp do_grant(client, permission, :undefined, group_to_grant) do
    case CogApi.permission_grant(client, permission, "groups", group_to_grant) do
      {:ok, _resp} ->
        IO.puts("Granted #{permission} to #{group_to_grant}")
        :ok
      {:error, resp} ->
        {:error, resp}
    end
  end
end
