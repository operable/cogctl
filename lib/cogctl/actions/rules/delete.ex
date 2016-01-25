defmodule Cogctl.Actions.Rules.Delete do
  use Cogctl.Action, "rules delete"
  alias Cogctl.CogApi

  def option_spec do
    [{:rule, ?r, 'rule', {:string, :undefined}, 'Rule id'}]
  end

  def run(options, _args, _config, profile) do
    client = CogApi.new_client(profile)
    case CogApi.authenticate(client) do
      {:ok, client} ->
        do_delete(client, :proplists.get_value(:rule, options))
      {:error, error} ->
        IO.puts "#{error["error"]}"
    end
  end

  defp do_delete(client, rule_id) do
    case CogApi.rule_delete(client, rule_id) do
      :ok ->
        IO.puts "Deleted #{rule_id}"
        :ok
      {:error, resp} ->
        {:error, resp}
    end
  end
end
