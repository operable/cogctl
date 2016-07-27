defmodule Cogctl.Actions.Bundle.DynamicConfig.Delete do
  use Cogctl.Action, "dynamic-config delete"

  alias CogApi.HTTP.Client, as: CogClient
  alias Cogctl.Actions.Bundle.DynamicConfig.Util

  def option_spec do
    [{:bundle, :undefined, :undefined, :string, 'Bundle name or id (required)'},
     {:layer, :undefined, :undefined, {:string, :undefined}, 'Configuration layer; if not specified, "base" is assumed'}]
  end

  def run(options, _args, _config, endpoint) do
    bundle = Keyword.get(options, :bundle)
    with {:ok, {layer, name}} <- Util.layer_and_name(options),
      do: with_authentication(endpoint, &do_delete(&1, bundle, layer, name))
  end

  defp do_delete(endpoint, bundle, layer, name) do
    with {:ok, bundle_id} <- Util.lookup_bundle(endpoint, bundle),
      do: delete_config(endpoint, bundle_id, layer, name) |> render(bundle, layer, name)
  end

  defp render(:ok, bundle, layer, name) do
    message = if layer == "base" do
      "Base dynamic config layer for bundle '#{bundle}' deleted successfully"
    else
      "#{layer}/#{name} dynamic config layer for bundle '#{bundle}' deleted successfully"
    end
    display_output(message)
  end
  defp render({:error, [message]}, _, _, _) do
    display_output(message)
  end

  defp delete_config(endpoint, bundle_id, layer, name) do
    CogClient.bundle_delete_dynamic_config(endpoint, bundle_id, layer, name)
  end

end
