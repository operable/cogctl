defmodule Cogctl.Actions.Triggers.Create do
  use Cogctl.Action, "triggers create"
  alias Cogctl.Table
  alias Cogctl.Actions.Triggers.Util

  def option_spec do
    [{:name, :undefined, 'name', :string, 'Trigger name (required)'},
     {:pipeline, :undefined, 'pipeline', :string, 'Pipeline text (required)'},
     {:enabled, :undefined, 'enabled', {:boolean, :undefined}, 'Enabled'},
     {:as_user, :undefined, 'as-user', {:string, :undefined}, 'Username of user to execute pipeline as'},
     {:timeout_sec, :undefined, 'timeout-sec', {:string, :undefined}, 'Timeout (seconds)'},
     {:description, :undefined, 'description', {:string, :undefined}, 'Description'}]
  end

  def run(options, _args, _config, endpoint) do
    params = convert_to_params(options)
    with_authentication(endpoint, &do_create(&1, params))
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
