defmodule Cogctl.Actions.Groups.Add do
  use Cogctl.Action, "groups add"
  alias Cogctl.CogApi

  @params [:name]

  def option_spec do
    [{:group, :undefined, :undefined, {:string, :undefined}, 'Group name'},
     {:user_to_add, :undefined, 'user', {:string, :undefined}, 'Username of user to add'},
     {:group_to_add, :undefined, 'group', {:string, :undefined}, 'Name of group to add'}]
  end

  def run(options, _args, _config, profile) do
    client = CogApi.new_client(profile)
    case CogApi.authenticate(client) do
      {:ok, client} ->
        group = :proplists.get_value(:group, options)
        user_to_add = :proplists.get_value(:user_to_add, options)
        group_to_add = :proplists.get_value(:group_to_add, options)
        do_add(client, group, user_to_add, group_to_add)
      {:error, error} ->
        IO.puts "#{error["error"]}"
    end
  end

  defp do_add(client, group, user_to_add, :undefined) do
    case CogApi.group_add(client, group, :users, user_to_add) do
      {:ok, _resp} ->
        IO.puts("Added #{user_to_add} to #{group}")
        :ok
      {:error, resp} ->
        {:error, resp}
    end
  end

  defp do_add(client, group, :undefined, group_to_add) do
    case CogApi.group_add(client, group, :groups, group_to_add) do
      {:ok, _resp} ->
        IO.puts("Added #{group_to_add} to #{group}")
        :ok
      {:error, resp} ->
        {:error, resp}
    end
  end
end
