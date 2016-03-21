defmodule Cogctl.Actions.Bundles.Enable do
  use Cogctl.Action, "bundles enable"

  def option_spec() do
    [{:bundle, :undefined, :undefined, {:string, :undefined}, 'Bundle name (required)'}]
  end

  def run(options, _args,  _config, client) do
    with_authentication(client,
                        &do_enable(&1, :proplists.get_value(:bundle, options)))
  end

  defp do_enable(client, bundle_name) do
    case CogApi.bundle_enable(client, bundle_name) do
      {:ok, _} ->
        display_output("Enabled #{bundle_name}")
      {:error, error} ->
        display_error(error["error"])
    end
  end
end
