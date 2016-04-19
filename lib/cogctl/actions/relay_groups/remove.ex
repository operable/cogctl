defmodule Cogctl.Actions.RelayGroups.Remove do
  use Cogctl.Action, "relay-groups remove"

  def option_spec() do
    [{:name, :undefined, :undefined, {:string, :undefined}, 'Relay Group name (required)'},
     {:relay, :undefined, 'relay', {:string, :undefined}, 'Relay name (required)'}]
  end

  def run(options, _args, _config, %{token: nil}=endpoint) do
    with_authentication(endpoint, &run(options, nil, nil, &1))
  end
  def run(options, _args, _config, endpoint) do
    case convert_to_params(options, [relay: :required,
                                     name: :required]) do
      {:ok, params} ->
        do_remove(endpoint, params)
      {:error, {:missing_params, missing_params}} ->
        display_arguments_error(missing_params)
    end
  end

  defp do_remove(endpoint, params) do
    case CogApi.HTTP.Client.relay_group_remove_relay(%{name: params.name}, %{relay: params.relay}, endpoint) do
      {:ok, _} ->
        display_output("Relay `#{params.relay}` removed from relay group `#{params.name}`")
        if last_relay?(endpoint, params.name),
          do: display_output("\tNOTE: There are no more relays in this group.")
      {:error, error} ->
        display_error(error)
    end
  end

  defp last_relay?(endpoint, group_name) do
    with {:ok, relay_group} <- CogApi.HTTP.Client.relay_group_show(%{name: group_name}, endpoint),
      do: relay_group.relays == []
  end
end
