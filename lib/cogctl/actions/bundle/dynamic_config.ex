defmodule Cogctl.Actions.Bundle.DynamicConfig do
  use Cogctl.Action, "dynamic-config"

  alias CogApi.HTTP.Client, as: CogClient
  alias Cogctl.Actions.Bundle.DynamicConfig.Util

  alias Cogctl.Table

  def option_spec,
    do: [{:bundle, :undefined, :undefined, :string, 'Bundle name or id (required)'}]

  def run(options, _args, _config, endpoint) do
    bundle = Keyword.get(options, :bundle)
    with_authentication(endpoint, &do_list(&1, bundle))
  end

  defp do_list(endpoint, bundle) do
    with {:ok, bundle_id} <- Util.lookup_bundle(endpoint, bundle),
      do: CogClient.bundle_dynamic_config_index(endpoint, bundle_id) |> render
  end

  defp render({:error, [message]}) do
    display_error(message)
  end
  defp render({:ok, configs}) do
    rows = configs
    |> Enum.sort_by(&(&1.layer))
    |> Enum.map(fn(config) ->
      case config.layer do
        "base" ->
          ["base"]
        _ ->
          ["#{config.layer}/#{config.name}"]
      end
    end)
    display_output(Table.format([["LAYER"]] ++ rows, true))
  end

end
