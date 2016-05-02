defmodule Cogctl.Actions.Relays.Disable do
  use Cogctl.Action, "relays disable"
  import Cogctl.Actions.Relays.Util, only: [update_status: 3]

  def option_spec() do
    [{:relay, :undefined, :undefined, :string, 'Relay name (required)'}]
  end

  def run(options, _args, _config, %{token: nil}=endpoint) do
    with_authentication(endpoint, &run(options, nil, nil, &1))
  end

  def run(options, _args, _config, endpoint) do
    case :proplists.get_value(:relay, options) do
      :undefined ->
        display_arguments_error
      relay_name ->
        update_status(endpoint, relay_name, false)
    end
  end
end
