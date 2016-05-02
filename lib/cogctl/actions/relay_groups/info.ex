defmodule Cogctl.Actions.RelayGroups.Info do
  use Cogctl.Action, "relay-groups info"
  import Cogctl.Actions.RelayGroups.Util, only: [get_details: 1, render: 5]

  def option_spec do
    [{:name, :undefined, :undefined, :string, 'Relay name (required)'}]
  end

  def run(options, _args, _config, %{token: nil}=endpoint) do
    with_authentication(endpoint, &run(options, nil, nil, &1))
  end
  def run(options, _args, _config, endpoint) do
    case :proplists.get_value(:name, options) do
      :undefined ->
        display_arguments_error
      group_name ->
        do_info(endpoint, group_name)
    end
  end

  defp do_info(endpoint, group_name) do
    case CogApi.HTTP.Client.relay_group_show(%{name: group_name}, endpoint) do
      {:ok, group} ->
        group_attrs = get_details(group)
        relay_attrs = Enum.map(group.relays, fn(relay) ->
            [relay.name, relay.id]
            end)
        bundle_attrs = Enum.map(group.bundles, fn(bundle) ->
            [bundle.name, bundle.id]
            end)
        render(group_attrs, [["NAME", "ID"]] ++ relay_attrs, [["NAME", "ID"]] ++ bundle_attrs, true, nil)
      {:error, error} ->
        display_error(error)
    end
  end
end
