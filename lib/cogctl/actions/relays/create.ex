defmodule Cogctl.Actions.Relays.Create do
  use Cogctl.Action, "relays create"
  import Cogctl.Actions.Relays.Util, only: [render: 2, render: 3]

  def option_spec do
    [{:name, :undefined, :undefined, {:string, :undefined}, 'Relay name (required)'},
     {:token, :undefined, 'token', {:string, :undefined}, 'Relay token (required)'},
     {:description, :undefined, 'description', {:string, :undefined}, 'Relay description'},
     {:groups, :undefined, 'groups', {:list, :undefined}, 'Relay groups'}]
  end

  def run(options, _args, _config, %{token: nil}=endpoint) do
    with_authentication(endpoint, &run(options, nil, nil, &1))
  end
  def run(options, _args, _config, endpoint) do
    case convert_to_params(options, option_spec, [name: :required,
                                                  token: :required,
                                                  description: :optional,
                                                  groups: :optional]) do
      {:ok, params} ->
        do_create(endpoint, params)
      _ ->
        display_arguments_error
    end
  end

  defp do_create(endpoint, params) do
    case CogApi.HTTP.Client.relay_create(params, endpoint) do
      {:ok, relay} ->
        relay_attrs = Enum.map([{"ID", :id}, {"Name", :name}], fn({title, attr}) ->
            [title, Map.fetch!(relay, attr)]
            end)
        case Map.get(params, :groups) do
          nil ->
            render(relay_attrs, false)
          relay_groups ->
            add_to_group(relay, relay_groups, endpoint)
            |> render(relay_attrs, false)
        end

      {:error, error} ->
        display_error(error)
    end
  end

  defp add_to_group(relay, relay_groups, endpoint) do
    Enum.flat_map_reduce(relay_groups, 0, fn(group, acc) ->
       case CogApi.HTTP.Client.relay_group_add_relay(%{name: group}, %{relay: relay.name}, endpoint) do
         {:ok, _} ->
           {["Adding '#{relay.name}' to relay group '#{group}': Ok."], acc}
         {:error, error} ->
           {["Adding '#{relay.name}' to relay group '#{group}': Error. " <> Enum.join(error, ", ")], acc + 1}
       end
    end)
  end
end
