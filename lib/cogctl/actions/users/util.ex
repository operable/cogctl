defmodule Cogctl.Actions.Users.Util do
  alias Cogctl.Table
  import Cogctl.ActionUtil , only: [display_output: 1, display_error: 1]

  def render(user_info, sort) do
    Table.format(user_info, sort) |> display_output
  end

  def render(user_info, group_info, role_info, sort) do
    Table.format(user_info, false)
        <> "\n\nGroups:\n" <> Table.format(group_info, sort)
        <> "\n\nRoles:\n" <> Table.format(role_info, sort)
    |> display_output
  end

end
