defmodule Cogctl.Actions.Bundle.DynamicConfig.Delete do
  use Cogctl.Action, "dynamic-config delete"

  alias CogApi.HTTP.Client, as: CogClient
  alias Cogctl.Actions.Bundle.DynamicConfig.Util

  def option_spec do
    [{:bundle, 98, 'bundle', :string, 'Bundle name or id (required)'}]
  end

  def run(options, _args, _config, endpoint) do
    bundle = Keyword.get(options, :bundle)
    with_authentication(endpoint, &do_delete(&1, bundle))
  end

  defp do_delete(endpoint, bundle) do
    with {:ok, bundle_id} <- Util.lookup_bundle(endpoint, bundle),
         do: delete_config(endpoint, bundle_id) |> render(bundle)
  end

  defp render(:ok, bundle) do
    "Successfully deleted dynamic config for bundle '#{bundle}'." |> display_output
  end
  defp render({:error, [nil]}, bundle) do
    "Dynamic config for bundle '#{bundle}' not found." |> display_output
  end

  defp delete_config(endpoint, bundle_id) do
    CogClient.bundle_delete_dynamic_config(endpoint, bundle_id)
  end

end
