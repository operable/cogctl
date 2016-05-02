defmodule Cogctl.Actions.Permissions.View do
  alias Cogctl.Table
  import Cogctl.ActionUtil , only: [display_output: 1]

  def render(permissions) when is_list(permissions) do
    format_table(permissions)
    |> Table.format(true)
    |> display_output
  end
  def render(permission) do
    format_table(permission)
    |> Table.format(false)
    |> display_output
  end

  def render_resource(nil), do: []
  def render_resource(permissions) do
    permission_names = Enum.map(permissions, &(&1.namespace <> ":" <> &1.name))
    |> Enum.sort
    |> Enum.join(",")

    [["Permissions", permission_names]]
  end

  defp format_table(permissions) when is_list(permissions) do
    [["NAMESPACE", "NAME", "ID"] | Enum.map(permissions, &([&1["namespace"], &1["name"], &1["id"]]))]
  end
  defp format_table(permission) do
    [
      ["ID",    permission.id],
      ["Namespace", permission.namespace],
      ["Name",  permission.name],
    ]
  end

end
