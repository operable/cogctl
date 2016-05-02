defmodule Cogctl.Actions.Triggers.Info do
  use Cogctl.Action, "triggers info"

  alias Cogctl.Table
  alias Cogctl.Actions.Triggers.Util

  def option_spec do
    [{:name, :undefined, :undefined, :string, 'Trigger name (required)'}]
  end

  def run(options, _args, _config, endpoint) do
    case :proplists.get_value(:name, options) do
      name when is_binary(name) ->
        with_authentication(endpoint, &do_info(&1, name))
      :undefined ->
        display_arguments_error
    end
  end

  defp do_info(endpoint, name) do
    case CogApi.HTTP.Client.trigger_show_by_name(endpoint, name) do
      {:ok, trigger} ->
        trigger_attr = Util.table(trigger)
        display_output("""
        #{Table.format(trigger_attr, false)}
        """ |> String.rstrip)

      {:error, error} ->
        display_error(error)
    end
  end
end
