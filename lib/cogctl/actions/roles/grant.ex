defmodule Cogctl.Actions.Roles.Grant do
  use Cogctl.Action, "roles grant"
  alias Cogctl.CogApi

  def option_spec do
    [{:role, :undefined, :undefined, {:string, :undefined}, 'Role name'},
     {:user_to_grant, :undefined, 'user', {:string, :undefined}, 'Username of user to grant role'},
     {:group_to_grant, :undefined, 'group', {:string, :undefined}, 'Name of group to grant role'}]
  end

  def run(options, _args, _config, profile) do
    client = CogApi.new_client(profile)
    case CogApi.authenticate(client) do
      {:ok, client} ->
        role = :proplists.get_value(:role, options)
        user_to_grant = :proplists.get_value(:user_to_grant, options)
        group_to_grant = :proplists.get_value(:group_to_grant, options)
        do_grant(client, role, user_to_grant, group_to_grant)
      {:error, error} ->
        IO.puts "#{error["error"]}"
    end
  end

  defp do_grant(client, role, user_to_grant, :undefined) do
    case CogApi.role_grant(client, role, "users", user_to_grant) do
      {:ok, _resp} ->
        IO.puts("Granted #{role} to #{user_to_grant}")
        :ok
      {:error, resp} ->
        {:error, resp}
    end
  end

  defp do_grant(client, role, :undefined, group_to_grant) do
    case CogApi.role_grant(client, role, "groups", group_to_grant) do
      {:ok, _resp} ->
        IO.puts("Granted #{role} to #{group_to_grant}")
        :ok
      {:error, resp} ->
        {:error, resp}
    end
  end
end
