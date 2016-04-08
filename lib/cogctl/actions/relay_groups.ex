defmodule Cogctl.Actions.RelayGroups do
  use Cogctl.Action, "relay-groups"
  import Cogctl.Actions.RelayGroups.Util, only: [render: 2]

  def option_spec do
    []
  end

  def run(_options, _args, _config, endpoint),
    do: with_authentication(endpoint, &do_list/1)

  defp do_list(endpoint) do
    case CogApi.HTTP.Client.relay_group_index(endpoint) do
      {:ok, relay_groups} ->
        relay_rows = Enum.map(relay_groups, &format_table(&1))
        render([["NAME", "CREATED", "ID"]] ++ relay_rows, true)
      {:error, error} ->
        display_error(error)
    end
  end

  defp format_table(group) do
    [Map.fetch!(group, :name),
     Map.fetch!(group, :inserted_at),
     Map.fetch!(group, :id)]
  end

end
