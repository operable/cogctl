defmodule Cogctl.Actions.RelayGroups.Add do
  use Cogctl.Action, "relay-groups add"

  def option_spec() do
    [{:relay_group, :undefined, :undefined, {:string, :undefined}, 'Relay Group name (required)'},
     # Technically this will just be the first relay
     {:relays, :undefined, :undefined, {:string, :undefined}, 'Relay names (required)'}]
  end

  def run(options, args, _config, endpoint) do
    # At least one relay is required, so we specify that here
    case convert_to_params(options, [relay_group: :required,
                                     relays: :required]) do
      {:ok, params} ->
        params = %{params | relays: [params.relays | args]}
        with_authentication(endpoint, &do_add(&1, params))
      {:error, {:missing_params, missing_args}} ->
        display_arguments_error(missing_args)
    end
  end

  defp do_add(endpoint, params) do
    case CogApi.HTTP.Client.relay_group_add_relays(%{name: params.relay_group}, %{relays: params.relays}, endpoint) do
      {:ok, _} ->
        display_output("Added '#{Enum.join(params.relays, ", ")}' to relay group '#{params.relay_group}'")
      {:error, error} ->
        display_error(error)
    end
  end
end
