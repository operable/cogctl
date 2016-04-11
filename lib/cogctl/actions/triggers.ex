defmodule Cogctl.Actions.Triggers do
  use Cogctl.Action, "triggers"
  alias Cogctl.Table

  def option_spec,
    do: []

  def run(_options, _args, _config, endpoint),
    do: with_authentication(endpoint, &do_list/1)

  defp do_list(endpoint) do
    case CogApi.HTTP.Client.trigger_index(endpoint) do
      {:ok, triggers} ->
        attrs = for t <- triggers do
          [t.name, t.id, t.pipeline]
        end
        display_output(Table.format([["Name", "ID", "Pipeline"]] ++ attrs, true))
      {:error, error} ->
        display_error(error)
    end
  end
end
