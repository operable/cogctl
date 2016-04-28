defmodule Cogctl.Actions.Triggers.Create do
  use Cogctl.Action, "triggers create"
  alias Cogctl.Table
  alias Cogctl.Actions.Triggers.Util

  def option_spec do
    [{:name, :undefined, 'name', {:string, :undefined}, 'Trigger name (required)'},
     {:pipeline, :undefined, 'pipeline', {:string, :undefined}, 'Pipeline text (required)'},
     {:enabled, :undefined, 'enabled', {:boolean, :undefined}, 'Enabled'},
     {:as_user, :undefined, 'as-user', {:string, :undefined}, 'User to execute pipeline as'},
     {:timeout_sec, :undefined, 'timeout-sec', {:string, :undefined}, 'Timeout (seconds)'},
     {:description, :undefined, 'description', {:string, :undefined}, 'Description'}]
  end

  def run(options, _args, _config, endpoint) do
    case convert_to_params(options, [name: :required,
                                     pipeline: :required,
                                     enabled: :optional,
                                     as_user: :optional,
                                     timeout_sec: :optional,
                                     description: :optional]) do
      {:ok, params} ->
        with_authentication(endpoint, &do_create(&1, params))
      {:error, {:missing_params, missing_params}} ->
        display_arguments_error(missing_params)
    end
  end

  defp do_create(endpoint, params) do
    case CogApi.HTTP.Client.trigger_create(endpoint, params) do
      {:ok, trigger} ->
        table_data = Util.table(trigger)

        Table.format(table_data, false) |> display_output
      {:error, error} ->
        display_error(error)
    end
  end

end
