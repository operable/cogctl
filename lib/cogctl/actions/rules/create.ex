defmodule Cogctl.Actions.Rules.Create do
  use Cogctl.Action, "rules create"
  alias Cogctl.CogApi
  alias Cogctl.Table

  @params [:rule_text]

  def option_spec do
    [{:rule_text, ?r, 'rule_text', {:string, :undefined}, 'Text of the rule'}]
  end

  def run(options, _args, _config, profile) do
    client = CogApi.new_client(profile)
    case CogApi.authenticate(client) do
      {:ok, client} ->
        do_create(client, options)
      {:error, error} ->
        IO.puts "#{error["error"]}"
    end
  end

  defp do_create(client, options) do
    params = make_rule_params(options)
    case CogApi.rule_create(client, %{rule: params.rule_text}) do
      {:ok, resp} ->
        rule = resp["rule"]

        rule_attrs = [{"ID", "Rule"}, {resp["id"], rule}]
        IO.puts("Added the rule '#{rule}'")
        IO.puts("")
        IO.puts(Table.format(rule_attrs))

        :ok
      {:error, resp} ->
        {:error, resp}
    end
  end

  defp make_rule_params(options) do
    options
    |> Keyword.take(@params)
    |> Enum.reject(&match?({_, :undefined}, &1))
    |> Enum.into(%{})
  end
end
