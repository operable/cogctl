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
    # TODO: This will change once the latest versions of of CogApi have completed
    #  testing and CogApi.role_show has been added to the CogApi. This will be
    #  completed in a separate PR.
    case CogApi.HTTP.Roles.role_index(endpoint) do
      {:ok, resp} ->
        roles = resp["roles"]
        filtered_roles = Enum.filter(roles, fn(role) -> role["name"] == role_name end)

        for role <- filtered_roles do
          role_attrs = [[role["name"], role["id"]]]

          permissions = role["permissions"]
          permission_attrs = Enum.reduce(Map.keys(permissions), [], fn(ns, acc) ->
              acc ++ Enum.map(permissions[ns], fn(perm) ->
                [ns, perm["name"], perm["id"]]
            end)
          end)

          display_output("""
                         #{Table.format([["NAME", "ID"]] ++ role_attrs, false)}

                         Permissions
                         #{Table.format([["NAMESPACE", "NAME", "ID"]] ++ permission_attrs, true)}
                         """ |> String.rstrip)
        end

      {:error, error} ->
        display_error(error["errors"])
    end
  end
end
