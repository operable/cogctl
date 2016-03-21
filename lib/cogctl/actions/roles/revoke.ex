defmodule Cogctl.Actions.Roles.Revoke do
  use Cogctl.Action, "roles revoke"

  def option_spec do
    [{:role, :undefined, :undefined, {:string, :undefined}, 'Role name (required)'},
     {:user_to_revoke, :undefined, 'user', {:string, :undefined}, 'Username of user to revoke role from'},
     {:group_to_revoke, :undefined, 'group', {:string, :undefined}, 'Name of group to revoke role from'}]
  end

  def run(options, _args, _config, endpoint) do
    role = :proplists.get_value(:role, options)
    user_to_revoke = :proplists.get_value(:user_to_revoke, options)
    group_to_revoke = :proplists.get_value(:group_to_revoke, options)

    with_authentication(endpoint,
                        &do_revoke(&1, role, user_to_revoke, group_to_revoke))
  end

  defp do_revoke(_endpoint, :undefined, _user_to_revoke, _group_to_revoke) do
    display_arguments_error
  end

  defp do_revoke(_endpoint, _role, :undefined, :undefined) do
    display_arguments_error
  end

  defp do_revoke(endpoint, role, user_to_revoke, :undefined) do
    case CogApi.HTTP.Old.role_revoke(endpoint, role, "users", user_to_revoke) do
      {:ok, _resp} ->
        display_output("Revoked #{role} from #{user_to_revoke}")
      {:error, error} ->
        display_error(error["errors"])
    end
  end

  defp do_revoke(endpoint, role, :undefined, group_to_revoke) do
    case CogApi.HTTP.Old.role_revoke(endpoint, role, "groups", group_to_revoke) do
      {:ok, _resp} ->
        display_output("Revoked #{role} from #{group_to_revoke}")
      {:error, error} ->
        display_error(error["errors"])
    end
  end

  defp do_revoke(_endpoint, _role, _user_to_revoke, _group_to_revoke) do
    display_arguments_error
  end
end
