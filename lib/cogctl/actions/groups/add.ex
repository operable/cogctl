defmodule Cogctl.Actions.Groups.Add do
  use Cogctl.Action, "groups add"
  alias Cogctl.Actions.Groups
  alias Cogctl.CogApi

  def option_spec do
    [{:group, :undefined, :undefined, {:string, :undefined}, 'Group name (required)'},
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
        display_error(error["error"])
    end
  end

  defp do_add(_client, :undefined, _user_to_add, _group_to_add) do
    display_arguments_error
  end

  defp do_add(_client, _group_name, :undefined, :undefined) do
    display_arguments_error
  end

  defp do_add(client, group_name, user_to_add, :undefined) do
    case CogApi.group_add(client, group_name, :users, user_to_add) do
      {:ok, resp} ->
        group = resp["group"]

        display_output("""
        Added #{user_to_add} to #{group_name}

        #{Groups.render_memberships(group)}
        """)
      {:error, error} ->
        display_error(error["error"])
    end
  end

  defp do_add(client, group_name, :undefined, group_to_add) do
    case CogApi.group_add(client, group_name, :groups, group_to_add) do
      {:ok, resp} ->
        group = resp["group"]

        display_output("""
        Added #{group_to_add} to #{group_name}

        #{Groups.render_memberships(group)}
        """)
      {:error, error} ->
        display_error(error["error"])
    end
  end

  defp do_add(_client, _group_name, _user_to_add, _group_to_add) do
    display_arguments_error
  end
end
