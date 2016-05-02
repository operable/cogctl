defmodule Cogctl.Actions.Triggers.Enable do
  use Cogctl.Action, "triggers enable"
  alias Cogctl.Actions.Triggers.Util

  def option_spec() do
    [{:trigger, :undefined, :undefined, :string, 'Trigger name (required)'}]
  end

  def run(options, _args, _config, endpoint) do
    case :proplists.get_value(:trigger, options) do
      trigger when is_binary(trigger) ->
        with_authentication(endpoint,
                            &Util.set_enabled(&1, trigger, true))
      _ ->
        display_arguments_error
    end
  end

end
