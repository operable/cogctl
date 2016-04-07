defmodule Cogctl.Actions.Relays do
  use Cogctl.Action, "relays"
  import Cogctl.Actions.Relays.Util, only: [render: 2, get_status: 1]

  def option_spec do
    []
  end

  def run(_options, _args, _config, endpoint),
    do: with_authentication(endpoint, &do_list/1)

  defp do_list(endpoint) do
    case CogApi.HTTP.Client.relay_index(endpoint) do
      {:ok, relays} ->
        relay_rows = Enum.map(relays, &format_table(&1))
        render([["NAME", "STATUS", "CREATED", "ID"]] ++ relay_rows, true)
      {:error, error} ->
        display_error(error)
    end
  end

  defp format_table(relay) do
    [Map.fetch!(relay, :name),
     get_status(Map.fetch!(relay, :enabled)),
     Map.fetch!(relay, :inserted_at),
     Map.fetch!(relay, :id)]
  end
end
