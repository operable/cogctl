defmodule Cogctl.Actions.Relays.Create do
  use Cogctl.Action, "relays create"
  import Cogctl.Actions.Relays.Util, only: [render: 3]

  def option_spec do
    [{:name, :undefined, :undefined, {:string, :undefined}, 'Relay name (required)'},
     {:token, :undefined, 'token', {:string, :undefined}, 'Relay token (required)'},
     {:description, :undefined, 'description', {:string, :undefined}, 'Relay description'}]
  end

  def run(options, _args, _config, %{token: nil}=endpoint) do
    with_authentication(endpoint, &run(options, nil, nil, &1))
  end
  def run(options, _args, _config, endpoint) do
    case convert_to_params(options, [name: :required,
                                     token: :required,
                                     description: :optional]) do
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
        render(relay_attrs, false, "Created #{relay.name}")
      {:error, error} ->
        display_error(error)
    end
  end
end
