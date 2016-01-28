defmodule Cogctl.Actions.Groups.Remove do
  use Cogctl.Action, "groups remove"
  alias Cogctl.Actions.Groups
  alias Cogctl.CogApi

  def option_spec do
    [{:group, :undefined, :undefined, {:string, :undefined}, 'Group name (required)'},
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
        display_error(error["error"])
    end
  end

  defp do_remove(_client, :undefined, _user_to_add, _group_to_add) do
    display_arguments_error
  end

  defp do_remove(_client, _group_name, :undefined, :undefined) do
    display_arguments_error
  end

  defp do_remove(client, group_name, user_to_remove, :undefined) do
    case CogApi.group_remove(client, group_name, :users, user_to_remove) do
      {:ok, resp} ->
        group = resp["group"]

        display_output("""
        Removed #{user_to_remove} from #{group_name}

        #{Groups.render_memberships(group)}
        """)
      {:error, error} ->
        display_error(error["error"])
    end
  end

  defp do_remove(client, group_name, :undefined, group_to_remove) do
    case CogApi.group_remove(client, group_name, :groups, group_to_remove) do
      {:ok, resp} ->
        group = resp["group"]

        display_output("""
        Removed #{group_to_remove} from #{group_name}

        #{Groups.render_memberships(group)}
        """)
      {:error, resp} ->
        {:error, resp}
    end
  end

  defp do_remove(_client, _group_name, _user_to_add, _group_to_add) do
    display_arguments_error
  end
end
