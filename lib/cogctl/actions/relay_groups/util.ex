defmodule Cogctl.Actions.RelayGroups.Util do
  alias Cogctl.Table
  import Cogctl.ActionUtil , only: [display_output: 1]

  def get_details(group) do
    [{"Name", Map.fetch!(group, :name)},
     {"ID", Map.fetch!(group, :id)},
     {"Creation Time", Map.fetch!(group, :inserted_at)}]
  end

  def render(group_info, sort) do
    Table.format(group_info, sort) |> display_output
  end

  # If the errorcount is not equal to 0, be sure that an error code
  # is returned upon execution
  def render({relay_messages, 0}, group_info, sort) do
    render_output(relay_messages, group_info, sort)
  end
  def render({relay_messages, _errorcount}, group_info, sort) do
    render_output(relay_messages, group_info, sort)
    :error
  end
  def render(group_info, sort, message) do
    message <> "\n\n" <> Table.format(group_info, sort) |> display_output
  end

  # If the errorcount is not equal to 0, be sure that an error code
  # is returned upon execution
  def render({relay_messages, 0}, group_info, sort, message) do
    render_output(relay_messages, group_info, sort, message)
  end
  def render({relay_messages, _errorcount}, group_info, sort, message) do
    render_output(relay_messages, group_info, sort, message)
    :error
  end

  def render(group_info, relay_info, bundle_info, sort, nil) do
    Table.format(group_info, false)
        <> "\n\nRelays\n" <> Table.format(relay_info, sort)
        <> "\n\nBundles\n" <> Table.format(bundle_info, sort)
    |> display_output
  end

  defp render_output(relay_messages, group_info, sort) do
    relay_message = Enum.join(relay_messages, "\n")
    Table.format(group_info, sort) <> "\n\n" <> relay_message
    |> display_output
  end

  defp render_output(relay_messages, group_info, sort, message) do
    relay_message = Enum.join(relay_messages, "\n")
    message <> relay_message <> "\n\n" <> Table.format(group_info, sort)
    |> display_output
  end
end
