defmodule Cogctl.Actions.Roles.Revoke do
  use Cogctl.Action, "roles revoke"
  alias Cogctl.CogApi

  @params [:name]

  def option_spec do
    [{:role, :undefined, :undefined, {:string, :undefined}, 'Role name'},
     {:user_to_revoke, :undefined, 'user', {:string, :undefined}, 'Username of user to revoke role from'},
     {:group_to_revoke, :undefined, 'group', {:string, :undefined}, 'Name of group to revoke role form'}]
  end

  def run(options, _args, _config, profile) do
    client = CogApi.new_client(profile)
    case CogApi.authenticate(client) do
      {:ok, client} ->
        role = :proplists.get_value(:role, options)
        user_to_revoke = :proplists.get_value(:user_to_revoke, options)
        group_to_revoke = :proplists.get_value(:group_to_revoke, options)
        do_revoke(client, role, user_to_revoke, group_to_revoke)
      {:error, error} ->
        IO.puts "#{error["error"]}"
    end
  end

  defp do_revoke(client, role, user_to_revoke, :undefined) do
    case CogApi.role_revoke(client, role, "users", user_to_revoke) do
      {:ok, _resp} ->
        IO.puts("Revoked #{role} from #{user_to_revoke}")
        :ok
      {:error, resp} ->
        {:error, resp}
    end
  end

  defp do_revoke(client, role, :undefined, group_to_revoke) do
    case CogApi.role_revoke(client, role, "groups", group_to_revoke) do
      {:ok, _resp} ->
        IO.puts("Revoked #{role} from #{group_to_revoke}")
        :ok
      {:error, resp} ->
        {:error, resp}
    end
  end
end
