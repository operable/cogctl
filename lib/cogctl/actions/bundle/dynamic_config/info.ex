defmodule Cogctl.Actions.Bundle.DynamicConfig.Info do
  use Cogctl.Action, "dynamic-config info"

  alias CogApi.HTTP.Client, as: CogClient
  alias Cogctl.Actions.Bundle.DynamicConfig.Util

  def option_spec do
    [{:bundle, :undefined, :undefined, :string, 'Bundle name or id (required)'},
     {:layer, :undefined, :undefined, {:string, :undefined}, 'Configuration layer; if not specified, "base" is assumed'}]
  end

  def run(options, _args, _config, endpoint) do
    bundle = Keyword.get(options, :bundle)
    with {:ok, {layer, name}} <- Util.layer_and_name(options),
      do: with_authentication(endpoint, &do_show(&1, bundle, layer, name))
  end

  defp do_show(endpoint, bundle, layer, name) do
    with {:ok, bundle_id} <- Util.lookup_bundle(endpoint, bundle),
      do: show_config(endpoint, bundle_id, layer, name) |> render
  end

  defp render({:error, [message]}) do
    display_error(message)
  end
  defp render({:ok, %{"dynamic_configuration" => %{"config" => config}}}) do
    # It'd be nice to spit this back out as the YAML we actually
    # consume, but alas, there doesn't seem to be an Elixir library
    # that actually does that :/
    Poison.encode!(config, pretty: true) |> display_output
  end

  defp show_config(endpoint, bundle_id, layer, name) do
    CogClient.bundle_show_dynamic_config(endpoint, bundle_id, layer, name)
  end

end
