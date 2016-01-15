defmodule Cogctl.Actions.Groups.Remove do
  use Cogctl.Action, "groups remove"
  alias Cogctl.CogApi

  @params [:name]

  def option_spec do
    [{:group, :undefined, :undefined, {:string, :undefined}, 'Group name'},
     {:user_to_remove, :undefined, 'user', {:string, :undefined}, 'Username of user to remove'},
     {:group_to_remove, :undefined, 'group', {:string, :undefined}, 'Name of group to remove'}]
  end

  def run(options, _args, _config, profile) do
    client = CogApi.new_client(profile)
    case CogApi.authenticate(client) do
      {:ok, client} ->
        group = :proplists.get_value(:group, options)
        user_to_remove = :proplists.get_value(:user_to_remove, options)
        group_to_remove = :proplists.get_value(:group_to_remove, options)
        do_remove(client, group, user_to_remove, group_to_remove)
      {:error, error} ->
        IO.puts "#{error["error"]}"
    end
  end

  defp do_remove(client, group, user_to_remove, :undefined) do
    case CogApi.group_remove(client, group, :users, user_to_remove) do
      {:ok, _resp} ->
        IO.puts("Removed #{user_to_remove} from #{group}")
        :ok
      {:error, resp} ->
        {:error, resp}
    end
  end

  defp do_remove(client, group, :undefined, group_to_remove) do
    case CogApi.group_remove(client, group, :groups, group_to_remove) do
      {:ok, _resp} ->
        IO.puts("Removed #{group_to_remove} from #{group}")
        :ok
      {:error, resp} ->
        {:error, resp}
    end
  end
end
