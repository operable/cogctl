defmodule Cogctl.Actions.Bundles.Disable do
  use Cogctl.Action, "bundles disable"

  def option_spec() do
    [{:bundle, :undefined, :undefined, {:string, :undefined}, 'Bundle name'}]
  end

  def run(options, _args,  _config, client) do
    with_authentication(client,
                        &do_disable(&1, :proplists.get_value(:bundle, options)))
  end

  defp do_disable(client, bundle_name) do
    case CogApi.bundle_disable(client, bundle_name) do
      {:ok, _} ->
        display_output("Disabled #{bundle_name}")
      {:error, error} ->
        display_error(error["error"])
    end
  end
end
