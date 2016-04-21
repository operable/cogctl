defmodule Cogctl.Actions.Roles.Util do
  alias Cogctl.Table
  alias CogApi.Resources.Role
  import Cogctl.ActionUtil , only: [display_output: 1, display_error: 1]

  def render(role_info, sort) do
    Table.format(role_info, sort) |> display_output
  end

  def render(%Role{}=role, groups, permissions) do
    role_info = format_role(role)
    group_info = format_groups(groups)
    permission_info = format_permissions(permissions)

    Table.format(role_info ++ permission_info ++ group_info, false)
    |> display_output
  end

  def render(role_info, sort, message) do
    message <> "\n\n" <> Table.format(role_info, sort) |> display_output
  end

  defp format_role(role) do
    [["ID:", role.id],
     ["Name:", role.name]]
  end

  defp format_groups(nil), do: []
  defp format_groups(groups) do
    group_names = Enum.map(groups, &(&1.name))
    |> Enum.sort
    |> Enum.join(",")

    [["Groups:", group_names]]
  end

  defp format_permissions(nil), do: []
  defp format_permissions(permissions) do
    permission_names = Enum.map(permissions, &(&1.namespace <> ":" <> &1.name))
    |> Enum.sort
    |> Enum.join(",")

    [["Permissions:", permission_names]]
  end

end
