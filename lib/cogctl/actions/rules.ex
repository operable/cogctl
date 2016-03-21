defmodule Cogctl.Actions.Rules do
  use Cogctl.Action, "rules"
  alias Cogctl.Table

  def option_spec do
    [{:command, :undefined, :undefined, {:string, :undefined}, 'Full command name including bundle name (required), Ex.: "operable:echo"'}]
  end

  def run(options, _args, _config, endpoint) do
    with_authentication(endpoint,
                        &do_list(&1, :proplists.get_value(:command, options)))
  end

  defp do_list(_endpoint, :undefined) do
    display_arguments_error
  end

  defp do_list(endpoint, command) do
    case CogApi.HTTP.Old.rule_index(endpoint, command) do
      {:ok, resp} ->
        rules = resp["rules"]
        rule_attrs = for rule <- rules do
          [rule["id"], rule["command"], rule["rule"]]
        end

        display_output(Table.format([["ID", "COMMAND", "RULE TEXT"]] ++ rule_attrs, true))
      {:error, error} ->
        display_error(error["errors"])
    end
  end
end
