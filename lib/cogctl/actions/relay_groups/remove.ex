defmodule Cogctl.Actions.RelayGroups.Remove do
  use Cogctl.Action, "relay-groups remove"

  @moduledoc """
  Used to remove relays from relay groups

  Usage:
  'cogctl relay-groups remove $RELAYGROUP --relays=$RELAY1,$RELAY2,$RELAY3'
  """

  def option_spec() do
    [{:relay_group, :undefined, :undefined, :string, 'Relay Group name (required)'},
     {:relays, :undefined, 'relays', :list, 'Relay names (required)'}]
  end

  def run(options, _args, _config, endpoint) do
    params = convert_to_params(options, [:relay_group, :relays])
    with_authentication(endpoint, &do_remove(&1, params))
  end

  defp do_remove(endpoint, params) do
    case CogApi.HTTP.Client.relay_group_remove_relays_by_name(params.relay_group, params.relays, endpoint) do
      {:ok, _} ->
        relay_string = List.wrap(params.relays)
        |> Enum.join(", ")
        output = ["Removed '#{relay_string}' from relay group '#{params.relay_group}'"]

        output = case last_relay?(endpoint, params.relay_group) do
          true ->
            output ++ ["NOTE: There are no more relays in this group."]
          false ->
            output
        end

        display_output(Enum.join(output, "\n\n"))

      {:error, error} ->
        display_error(error)
    end
  end

  defp last_relay?(endpoint, group_name) do
    with {:ok, relay_group} <- CogApi.HTTP.Client.relay_group_show(%{name: group_name}, endpoint),
      do: relay_group.relays == []
  end
end
