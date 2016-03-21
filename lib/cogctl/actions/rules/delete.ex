defmodule Cogctl.Actions.Rules.Delete do
  use Cogctl.Action, "rules delete"

  def option_spec do
    [{:rule, :undefined, :undefined, {:string, :undefined}, 'Rule id'}]
  end

  def run(options, _args, _config, client) do
    with_authentication(client,
                        &do_delete(&1, :proplists.get_value(:rule, options)))
  end

  defp do_delete(_client, :undefined) do
    display_arguments_error
  end

  defp do_delete(client, rule_id) do
    case CogApi.rule_delete(client, rule_id) do
      :ok ->
        display_output("Deleted #{rule_id}")
      {:error, error} ->
        display_error(error["errors"])
    end
  end
end
