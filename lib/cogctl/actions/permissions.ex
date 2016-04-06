defmodule Cogctl.Actions.Permissions do
  use Cogctl.Action, "permissions"
  alias Cogctl.Table

  def option_spec do
    [{:role, :undefined, 'role', {:string, :undefined}, 'Name of role to filter permissions by'}]
  end

  def run(options, _args, _config, endpoint) do
    params = convert_to_params(options, role: :optional)
    with_authentication(endpoint, &do_list(&1, params))
  end

  defp do_list(_endpoint, :error) do
    display_arguments_error
  end

  defp do_list(endpoint, {:ok, params}) do
    case CogApi.HTTP.Internal.permission_index(endpoint, params) do
      {:ok, resp} ->
        permissions = resp["permissions"]
        permission_attrs = Enum.map(permissions, fn(permission) ->
                               [permission["namespace"], permission["name"], permission["id"]]
                           end)

        display_output(Table.format([["NAMESPACE", "NAME", "ID"]] ++ permission_attrs, true))
      {:error, error} ->
        display_error(error["errors"])
    end
  end
end
