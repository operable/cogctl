defmodule Cogctl.Actions.RelayGroups.Add do
  use Cogctl.Action, "relay-groups add"

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
        do_add(endpoint, params)
      _ ->
        display_arguments_error
    end
  end

  defp do_add(endpoint, params) do
    case CogApi.HTTP.Client.relay_group_add_relay(%{name: params.name}, %{relay: params.relay}, endpoint) do
      {:ok, _} ->
        display_output("Relay `#{params.relay}` added to relay group `#{params.name}`")
      {:error, error} ->
        display_error(error)
    end
  end
end
