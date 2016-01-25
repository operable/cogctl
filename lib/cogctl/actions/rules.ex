defmodule Cogctl.Actions.Rules do
  use Cogctl.Action, "rules"
  alias Cogctl.CogApi
  alias Cogctl.Table

  def option_spec do
    [{:command, :undefined, :undefined, {:string, :undefined}, 'Full command name including bundle name, Ex.: "operable:echo"'}]
  end

  def run(options, _args, _config, profile) do
    client = CogApi.new_client(profile)
    case CogApi.authenticate(client) do
      {:ok, client} ->
        do_list(client, :proplists.get_value(:command, options))
      {:error, error} ->
        IO.puts "#{error["error"]}"
    end
  end

  defp do_list(client, command) do
    case CogApi.rule_show(client, command) do
      {:ok, resp} ->
        rules = resp["rules"]
        rule_attrs = for rule <- rules do
          [rule["id"], rule["command"], rule["rule"]]
        end

        IO.puts(Table.format([["ID", "COMMAND", "RULE TEXT"]] ++ rule_attrs))

        :ok
      {:error, resp} ->
        {:error, resp}
    end
  end
end
