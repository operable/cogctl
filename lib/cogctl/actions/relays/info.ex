defmodule Cogctl.Actions.Relays.Info do
  use Cogctl.Action, "relays info"
  import Cogctl.Actions.Relays.Util, only: [get_details: 1, render: 4]

  def option_spec do
    [{:relay, :undefined, :undefined, {:string, :undefined}, 'Relay name (required)'}]
  end

  def run(options, _args, _config, %{token: nil}=endpoint) do
    with_authentication(endpoint, &run(options, nil, nil, &1))
  end
  def run(options, _args, _config, endpoint) do
    case :proplists.get_value(:relay, options) do
      :undefined ->
        display_arguments_error
      relay_name ->
        do_info(endpoint, relay_name)
    end
  end

  defp do_info(endpoint, relay_name) do
    case CogApi.HTTP.Client.relay_show(%{name: relay_name}, endpoint) do
      {:ok, relay} ->
        relay_attrs = get_details(relay)
        group_attrs = Enum.map(relay.groups, fn(group) ->
            [group.name, group.id]
            end)
        render(relay_attrs, [["NAME", "ID"]] ++ group_attrs, true, nil)
      {:error, error} ->
        display_error(error)
    end
  end
end
