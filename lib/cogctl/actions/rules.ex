defmodule Cogctl.Actions.Rules do
  use Cogctl.Action, "rules"
  alias Cogctl.Table

  def option_spec do
    [{:command, :undefined, :undefined, {:string, :undefined}, 'Full command name including bundle name (required), Ex.: "operable:echo"'}]
  end

  def run(options, _args, _config, client) do
    case CogApi.authenticate(client) do
      {:ok, client} ->
        do_list(client, :proplists.get_value(:command, options))
      {:error, error} ->
        display_error(error["errors"])
    end
  end

  defp do_list(_client, :undefined) do
    display_arguments_error
  end

  defp do_list(client, command) do
    case CogApi.rule_index(client, command) do
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
