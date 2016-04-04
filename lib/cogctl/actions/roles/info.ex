defmodule Cogctl.Actions.Roles.Info do
  use Cogctl.Action, "roles info"
  alias Cogctl.Table

  def option_spec do
    [{:role, :undefined, :undefined, {:string, :undefined}, 'Role name (required)'}]
  end

  def run(options, _args, _config, endpoint) do
    with_authentication(endpoint,
                        &do_info(&1, :proplists.get_value(:role, options)))
  end

  defp do_info(_endpoint, :undefined) do
    display_arguments_error
  end

  defp do_info(endpoint, role_name) do
    case CogApi.HTTP.Roles.show(endpoint, %{name: role_name}) do
      {:ok, role} ->
        role_attrs = [[Map.fetch!(role, :name), Map.fetch!(role, :id)]]

        permission_attrs = Enum.map(role.permissions, fn(permission) ->
                               [permission.namespace, permission.name, permission.id]
                           end)
        display_output("""
                       #{Table.format([["NAME", "ID"]] ++ role_attrs, false)}

                       Permissions
                       #{Table.format([["NAMESPACE", "NAME", "ID"]] ++ permission_attrs, true)}
                       """ |> String.rstrip)

      {:error, error} ->
        display_error(error["errors"])
    end
  end
end
