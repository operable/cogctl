defmodule Cogctl.Actions.Groups.Remove do
  use Cogctl.Action, "groups remove"
  alias Cogctl.Actions.Groups

  def option_spec do
    [{:group, :undefined, :undefined, {:string, :undefined}, 'Group name (required)'},
     {:user_to_remove, :undefined, 'user', {:string, :undefined}, 'Username of user to remove'},
     {:group_to_remove, :undefined, 'group', {:string, :undefined}, 'Name of group to remove'}]
  end

  def run(options, _args, _config, endpoint) do
    group = :proplists.get_value(:group, options)
    user_to_remove = :proplists.get_value(:user_to_remove, options)
    group_to_remove = :proplists.get_value(:group_to_remove, options)

    with_authentication(endpoint,
                        &do_remove(&1, group, user_to_remove, group_to_remove))
  end

  defp do_remove(_endpoint, :undefined, _user_to_add, _group_to_add) do
    display_arguments_error
  end

  defp do_remove(_endpoint, _group_name, :undefined, :undefined) do
    display_arguments_error
  end

  defp do_remove(endpoint, group_name, user_to_remove, :undefined) do
    case CogApi.HTTP.Old.group_remove(endpoint, group_name, :users, user_to_remove) do
      {:ok, resp} ->
        group = resp["group"]

        display_output("""
        Removed #{user_to_remove} from #{group_name}

        #{Groups.render_memberships(group)}
        """ |> String.rstrip)
      {:error, error} ->
        display_error(error["errors"])
    end
  end

  defp do_remove(endpoint, group_name, :undefined, group_to_remove) do
    case CogApi.HTTP.Old.group_remove(endpoint, group_name, :groups, group_to_remove) do
      {:ok, resp} ->
        group = resp["group"]

        display_output("""
        Removed #{group_to_remove} from #{group_name}

        #{Groups.render_memberships(group)}
        """ |> String.rstrip)
      {:error, resp} ->
        {:error, resp}
    end
  end

  defp do_remove(_endpoint, _group_name, _user_to_add, _group_to_add) do
    display_arguments_error
  end
end
