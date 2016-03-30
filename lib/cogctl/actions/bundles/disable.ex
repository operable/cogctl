defmodule Cogctl.Actions.Bundles.Disable do
  use Cogctl.Action, "bundles disable"

  def option_spec() do
    [{:bundle, :undefined, :undefined, {:string, :undefined}, 'Bundle name'}]
  end

  def run(options, _args,  _config, endpoint) do
    with_authentication(endpoint,
                        &do_disable(&1, :proplists.get_value(:bundle, options)))
  end

  defp do_disable(endpoint, bundle_name) do
    case CogApi.HTTP.Bundles.update(endpoint, %{name: bundle_name}, %{enabled: false}) do
      {:ok, _} ->
        display_output("Disabled #{bundle_name}")
      {:error, error} ->
        display_error(error["errors"])
    end
  end
end
