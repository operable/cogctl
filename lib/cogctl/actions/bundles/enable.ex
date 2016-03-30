defmodule Cogctl.Actions.Bundles.Enable do
  use Cogctl.Action, "bundles enable"

  def option_spec() do
    [{:bundle, :undefined, :undefined, {:string, :undefined}, 'Bundle name (required)'}]
  end

  def run(options, _args,  _config, endpoint) do
    with_authentication(endpoint,
                        &do_enable(&1, :proplists.get_value(:bundle, options)))
  end

  defp do_enable(endpoint, bundle_name) do
    case CogApi.HTTP.Bundles.update(endpoint, %{name: bundle_name}, %{enabled: false}) do
      {:ok, _} ->
        display_output("Enabled #{bundle_name}")
      {:error, error} ->
        display_error(error["errors"])
    end
  end
end
