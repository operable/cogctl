defmodule Cogctl.Actions.Relays.Create do
  use Cogctl.Action, "relays create"
  alias Cogctl.Actions.Relays.Util

  def option_spec do
    [{:name, :undefined, :undefined, :string, 'Relay name (required)'},
     {:token, :undefined, 'token', :string, 'Relay token (required)'},
     {:enable, :undefined, 'enable', {:boolean, false}, 'Flag to enable the relay (default false)'},
     {:description, :undefined, 'description', {:string, :undefined}, 'Relay description'},
     {:groups, :undefined, 'groups', {:list, :undefined}, 'Relay groups'},
     {:id, :undefined, 'id', {:string, :undefined}, 'Relay id (must be uuid)'}]
  end

  def run(options, _args, _config, endpoint) do
    params = convert_to_params(options, [:name, :token, :enable, :description, :groups, :id])
    with_authentication(endpoint, &do_create(&1, params))
  end

  defp do_create(endpoint, params) do
    with {:ok, relay} <- create_relay(endpoint, params),
         {:ok, updated} <- enable_relay(endpoint, relay, params.enable),
         {_, group_msgs} <- add_to_group(updated, Map.get(params, :groups, []), endpoint),
         do: Util.render(updated, group_msgs)
  end

  defp create_relay(endpoint, params) do
    case CogApi.HTTP.Client.relay_create(params, endpoint) do
      {:ok, relay} ->
        {:ok, relay}
      {:error, error} ->
        display_error(error)
    end
  end

  defp enable_relay(_endpoint, relay, false), do: {:ok, relay}
  defp enable_relay(endpoint, relay, true) do
    case CogApi.HTTP.Client.relay_update(%{name: relay.name}, %{enabled: true}, endpoint) do
      {:ok, updated} ->
        {:ok, updated}
      {:error, error} ->
        display_error(error)
    end
  end

  defp add_to_group(_relay, [], _endpoint), do: {:ok, {[], 0}}
  defp add_to_group(relay, relay_groups, endpoint) do
    {msgs, errorcount} = Enum.map_reduce(relay_groups, 0, fn(group, acc) ->
       case CogApi.HTTP.Client.relay_group_add_relays_by_name(group, relay.name, endpoint) do
         {:ok, _} ->
           {["Adding '#{relay.name}' to relay group '#{group}': Ok."], acc}
         {:error, error} ->
           {["Adding '#{relay.name}' to relay group '#{group}': Error. " <> Enum.join(error, ", ")], acc + 1}
       end
    end)
    if errorcount == length(msgs) and errorcount > 0 do
      {:error, {msgs, errorcount}}
    else
      {:ok, {msgs, errorcount}}
    end
  end
end
