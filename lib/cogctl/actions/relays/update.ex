defmodule Cogctl.Actions.Relays.Update do
  use Cogctl.Action, "relays update"
  import Cogctl.Actions.Relays.Util, only: [get_details: 1, render: 4]

  def option_spec do
    [{:relay, :undefined, :undefined, {:string, :undefined}, 'Current Relay name (required)'},
     {:name, :undefined, 'name', {:string, :undefined}, 'name'},
     {:token, :undefined, 'token', {:string, :undefined}, 'token'},
     {:description, :undefined, 'description', {:string, :undefined}, 'description'}]
  end

  def run(options, _args, _config, %{token: nil}=endpoint) do
    with_authentication(endpoint, &run(options, nil, nil, &1))
  end
  def run(options, _args, _config, endpoint) do
    case convert_to_params(options, [relay: :required,
                                     name: :optional,
                                     token: :optional,
                                     description: :optional]) do
      {:ok, params} ->
        do_update(endpoint, params)
      _ ->
        display_arguments_error
    end
  end

  defp do_update(endpoint, params) do
    case CogApi.HTTP.Client.relay_update(%{name: params.relay}, params, endpoint) do
      {:ok, relay} ->
        relay_attrs = get_details(relay)
        group_rows = Enum.map(relay.groups, fn(group) ->
            [group.name, group.id]
            end)
        render(relay_attrs, [["NAME", "ID"]] ++ group_rows, true, "Updated #{relay.name}")
      {:error, error} ->
        display_error(error)
    end
  end
end
