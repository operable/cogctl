defmodule Cogctl.Actions.Rules.Create do
  use Cogctl.Action, "rules create"
  alias Cogctl.Table

  def option_spec do
    [{:rule_text, ?r, 'rule-text', {:string, :undefined}, 'Text of the rule (required)'}]
  end

  def run(options, _args, _config, endpoint) do
    with_authentication(endpoint,
                        &do_create(&1, :proplists.get_value(:rule_text, options)))
  end

  defp do_create(_endpoint, :undefined) do
    display_arguments_error
  end

  defp do_create(endpoint, rule_text) do
    case CogApi.HTTP.Internal.rule_create(endpoint, %{rule: rule_text}) do
      {:ok, resp} ->
        rule = resp["rule"]
        rule_attrs = [{"ID", resp["id"]}, {"Rule Text", rule}]

        Table.format(rule_attrs, false) |> display_output
      {:error, error} ->
        display_error(error["errors"])
    end
  end
end
