defmodule Cogctl.Actions.Groups do
  use Cogctl.Action, "groups"

  alias Cogctl.Table
  alias CogApi.HTTP.Client

  def option_spec do
    []
  end

  def run(_options, _args, _config, endpoint),
  do: with_authentication(endpoint, &do_list/1)

  defp do_list(endpoint) do
    case Client.group_index(endpoint) do
      {:ok, groups} ->
        group_rows = Enum.map(groups, fn(group) -> [group.name, group.id] end)
        display_output(Table.format([["NAME", "ID"]] ++ group_rows, true))
      {:error, message} ->
        display_error(message)
    end
  end

  def render(group) do
    format_table(group) |> display_output
  end

  def render(group, message) do
    message <> "\n\n" <> format_table(group) |> display_output
  end

  defp format_table(group) do
    group_rows = [
      {"ID",    group.id},
      {"Name",  group.name},
      {"Users", Enum.map(group.users, &(&1.username)) |> Enum.join(", ")},
      {"Roles", Enum.map(group.roles, &(&1.name)) |> Enum.join(", ")}
    ]

    Table.format(group_rows, false)
  end

  def find_by_name(endpoint, name) do
    case Client.group_find(endpoint, name: name) do
      {:ok, group} ->
        group
      _ ->
        :undefined
    end
  end

end
