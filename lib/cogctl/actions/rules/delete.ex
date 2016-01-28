defmodule Cogctl.Actions.Rules.Delete do
  use Cogctl.Action, "rules delete"
  alias Cogctl.CogApi

  def option_spec do
    [{:rule, :undefined, :undefined, {:string, :undefined}, 'Rule id'}]
  end

  def run(options, _args, _config, profile) do
    client = CogApi.new_client(profile)
    case CogApi.authenticate(client) do
      {:ok, client} ->
        do_delete(client, :proplists.get_value(:rule, options))
      {:error, error} ->
        display_error(error["errors"])
    end
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
