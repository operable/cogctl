defmodule Cogctl.Actions.Permissions.View do
  alias Cogctl.Table
  import Cogctl.ActionUtil , only: [display_output: 1]

  def render(permission) do
    format_table(permission)
    |> Table.format(false)
    |> display_output
  end

  defp format_table(permission) do
    [
      ["ID",    permission.id],
      ["Namespace", permission.namespace],
      ["Name",  permission.name],
    ]
  end

end
