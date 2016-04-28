defmodule Cogctl.Actions.Triggers.Delete do
  use Cogctl.Action, "triggers delete"

  def option_spec do
    [{:name, :undefined, :undefined, :string, 'name (required)'}]
  end

  def run(options, _args, _config, endpoint) do
    case :proplists.get_value(:name, options) do
      name when is_binary(name) ->
        with_authentication(endpoint, &do_delete(&1, name))
      :undefined ->
        display_arguments_error
    end
  end

  defp do_delete(endpoint, name) do
    case CogApi.HTTP.Client.trigger_show_by_name(endpoint, name) do
      {:ok, trigger} ->
        case CogApi.HTTP.Client.trigger_delete(endpoint, trigger.id) do
          :ok ->
            display_output("Deleted #{name}")
          {:error, error} ->
            display_error(error)
        end
      {:error, error} ->
        display_error(error)
    end
  end
end
