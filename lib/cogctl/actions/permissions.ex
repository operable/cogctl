defmodule Cogctl.Actions.Permissions do
  use Cogctl.Action, "permissions"
  alias Cogctl.Actions.Permissions.View, as: PermissionView

  def option_spec do
    [{:role, :undefined, 'role', {:string, :undefined}, 'Name of role to filter permissions by'}]
  end

  def run(options, _args, _config, endpoint) do
    params = convert_to_params(options, role: :optional)
    with_authentication(endpoint, &do_list(&1, params))
  end

  defp do_list(_endpoint, {:error, {:missing_params, missing_params}}) do
    display_arguments_error(missing_params)
  end

  defp do_list(endpoint, {:ok, params}) do
    case CogApi.HTTP.Internal.permission_index(endpoint, params) do
      {:ok, resp} ->
        permissions = resp["permissions"]
        PermissionView.render(permissions)
      {:error, error} ->
        display_error(error["errors"])
    end
  end
end
