defmodule Cogctl.Actions.Rules.Update do
  use Cogctl.Action, "rules update"
  alias Cogctl.CogApi
  alias Cogctl.Table

  # Whitelisted options passed as params to api client
  @params [:id]

  def option_spec do
    [{:rule, :undefined, :undefined, {:string, :undefined}, 'Rule id'},
     {:command, :undefined, 'command', {:string, :undefined}, 'Name'}]
  end

  def run(options, _args, _config, profile) do
    client = CogApi.new_client(profile)
    case CogApi.authenticate(client) do
      {:ok, client} ->
        do_update(client, :proplists.get_value(:rule, options), options)
      {:error, error} ->
        IO.puts "#{error["error"]}"
    end
  end

  defp do_update(client, rule_id, options) do
    params = make_rule_params(options)
    case CogApi.rule_update(client, rule_id, %{rule: params}) do
      {:ok, resp} ->
        rule = resp["rule"]
        rule_attrs = for {id, command, text} <- [{"ID", "id"}, {"Command", "command"}, {"Rule", "rule"}] do
          [id, rule[command], rule[text]]
        end

        IO.puts("Updated #{rule_id}")
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
