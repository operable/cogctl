defmodule Cogctl.Actions.RelayGroups.Create do
  use Cogctl.Action, "relay-groups create"
  import Cogctl.Actions.RelayGroups.Util, only: [render: 2, render: 3]

  def option_spec do
    [{:name, :undefined, :undefined, :string, 'Relay Group name (required)'},
     {:members, :undefined, 'members', {:list, :undefined}, 'Relay names'}]
  end

  def run(options, _args, _config, %{token: nil}=endpoint) do
    with_authentication(endpoint, &run(options, nil, nil, &1))
  end
  def run(options, _args, _config, endpoint) do
    params = convert_to_params(options)
    do_create(endpoint, params)
  end

  defp do_create(endpoint, params) do
    case CogApi.HTTP.Client.relay_group_create(params, endpoint) do
      {:ok, group} ->
        group_attrs = Enum.map([{"ID", :id}, {"Name", :name}], fn({title, attr}) ->
            [title, Map.fetch!(group, attr)]
            end)
        case Map.get(params, :members) do
          nil ->
            render(group_attrs, false)
          relays ->
            add_to_group(group, relays, endpoint)
            |> render(group_attrs, false)
        end
      {:error, error} ->
        display_error(error)
    end
  end

  defp add_to_group(group, relays, endpoint) do
    Enum.flat_map_reduce(relays, 0, fn(relay, acc) ->
       case CogApi.HTTP.Client.relay_group_add_relays_by_name(group.name, relay, endpoint) do
         {:ok, _} ->
           {["Adding '#{relay}' to relay group '#{group.name}': Ok."], acc}
         {:error, error} ->
           {["Adding '#{relay}' to relay group '#{group.name}': Error. " <> Enum.join(error, ", ")], acc + 1}
       end
    end)
  end
end
