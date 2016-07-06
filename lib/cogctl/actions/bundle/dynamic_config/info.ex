defmodule Cogctl.Actions.Bundle.DynamicConfig.Info do
  use Cogctl.Action, "dynamic-config info"

  alias CogApi.HTTP.Client, as: CogClient
  alias Cogctl.Actions.Bundle.DynamicConfig.Util

  def option_spec do
    [{:bundle, ?b, 'bundle', :string, 'Bundle name or id (required)'}]
  end

  def run(options, _args, _config, endpoint) do
    bundle = Keyword.get(options, :bundle)
    with_authentication(endpoint, &do_show(&1, bundle))
  end

  defp do_show(endpoint, bundle) do
    with {:ok, bundle_id} <- Util.lookup_bundle(endpoint, bundle),
         do: show_config(endpoint, bundle_id) |> render(bundle)
  end

  defp render({:error, [nil]}, bundle) do
    "Dynamic config for bundle '#{bundle}' not found." |> display_error
  end
  defp render({:ok, %{"dynamic_configuration" => %{"config" => config}}}, _bundle) do
    Poison.encode!(config, pretty: true) |> display_output
  end

  defp show_config(endpoint, bundle_id) do
    CogClient.bundle_show_dynamic_config(endpoint, bundle_id)
  end

end
