defmodule Cogctl.Actions.Triggers.Update do
  use Cogctl.Action, "triggers update"
  alias Cogctl.Table
  alias Cogctl.Actions.Triggers.Util
  def option_spec do
    [
      {:trigger, :undefined, :undefined, {:string, :undefined}, 'Trigger name (required)'},

      {:name, :undefined, 'name', {:string, :undefined}, 'Trigger name'},
      {:pipeline, :undefined, 'pipeline', {:string, :undefined}, 'Pipeline text'},
      {:enabled, :undefined, 'enabled', {:boolean, :undefined}, 'Enabled'},
      {:as_user, :undefined, 'as-user', {:string, :undefined}, 'User to execute pipeline as'},
      {:timeout_sec, :undefined, 'timeout-sec', {:string, :undefined}, 'Timeout (seconds)'},
      {:description, :undefined, 'description', {:string, :undefined}, 'Description'}]
  end

  def run(options, _args, _config, endpoint) do
    params = convert_to_params(options, [name: :optional,
                                         pipeline: :optional,
                                         enabled: :optional,
                                         as_user: :optional,
                                         timeout_sec: :optional,
                                         description: :optional])
    name = :proplists.get_value(:trigger, options)

    case {name, params} do
      {name, {:ok, params}} when is_binary(name) ->
        with_authentication(endpoint,
                            &do_update(&1, name, params))
      {:error, {:missing_params, missing_params}} ->
        display_arguments_error(missing_params)
    end
  end

  defp do_update(endpoint, trigger_name, params) do
    case Util.update(endpoint, trigger_name, params) do
      {:ok, updated} ->
        table_data = Util.table(updated)
        display_output("""
        Updated #{trigger_name}

        #{Table.format(table_data, false)}
        """ |> String.rstrip)
      {:error, error} ->
        display_error(error)
    end
  end

end
