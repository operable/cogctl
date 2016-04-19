defmodule Cogctl.Actions.RelayGroups.Remove do
  use Cogctl.Action, "relay-groups remove"

  def option_spec() do
    [{:relay_group, :undefined, :undefined, {:string, :undefined}, 'Relay Group name (required)'},
     # Technically this will just be the first bundle
     {:relays, :undefined, :undefined, {:string, :undefined}, 'Relay names (required)'}]
  end

  def run(options, args, _config, endpoint) do
    case convert_to_params(options, [relay_group: :required,
                                     relays: :required]) do
      {:ok, params} ->
        params = %{params | relays: [params.relays | args]}
        with_authentication(endpoint, &do_remove(&1, params))
      {:error, {:missing_params, missing_params}} ->
        display_arguments_error(missing_params)
    end
  end

  defp do_remove(endpoint, params) do
    case CogApi.HTTP.Client.relay_group_remove_relays(%{name: params.relay_group}, %{relays: params.relays}, endpoint) do
      {:ok, _} ->
        output = ["Removed `#{params.relays}` from relay group `#{params.relay_group}`"]

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
