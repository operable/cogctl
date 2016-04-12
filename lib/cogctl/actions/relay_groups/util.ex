defmodule Cogctl.Actions.RelayGroups.Util do
  alias Cogctl.Table
  import Cogctl.ActionUtil , only: [display_output: 1, display_error: 1]

  def get_details(group) do
    [{"Name", Map.fetch!(group, :name)},
     {"ID", Map.fetch!(group, :id)},
     {"Creation Time", Map.fetch!(group, :inserted_at)}]
  end

  def render(group_info, sort) do
    Table.format(group_info, sort) |> display_output
  end

  def render(group_info, sort, message) do
    message <> "\n\n" <> Table.format(group_info, sort) |> display_output
  end

  def render(group_info, relay_info, bundle_info, sort, nil) do
    Table.format(group_info, false)
        <> "\n\nRelays\n" <> Table.format(relay_info, sort)
        <> "\n\nBundles\n" <> Table.format(bundle_info, sort)
    |> display_output
  end
end
