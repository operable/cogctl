defmodule Cogctl.Actions.Permissions do
  use Cogctl.Action, "permissions"
  alias Cogctl.Table

  def option_spec do
    [{:user, :undefined, 'user', {:string, :undefined}, 'Username of user to filter permissions by'},
     {:group, :undefined, 'group', {:string, :undefined}, 'Name of group to filter permissions by'},
     {:role, :undefined, 'role', {:string, :undefined}, 'Name of role to filter permissions by'}]
  end

  def run(options, _args, _config, client) do
    params = convert_to_params(options, [user: :optional, group: :optional, role: :optional])
    with_authentication(client,
                        &do_list(&1, params))
  end

  defp do_list(_client, :error) do
    display_arguments_error
  end

  defp do_list(client, {:ok, params}) do
    case CogApi.permission_index(client, params) do
      {:ok, resp} ->
        permissions = resp["permissions"]
        permission_attrs = for permission <- permissions do
          namespace_name = permission["namespace"]["name"]
          permission_name = permission["name"]

          ["#{namespace_name}:#{permission_name}", permission["id"]]
        end

        display_output(Table.format([["NAME", "ID"]] ++ permission_attrs, true))
      {:error, error} ->
        display_error(error["error"])
    end
  end
end
