defmodule Cogctl.Actions.Bundles.Enable do
  use Cogctl.Action, "bundles enable"

  def option_spec() do
    [{:bundle, :undefined, :undefined, {:string, :undefined}, 'Bundle name (required)'}]
  end

  def run(options, _args,  _config, client) do
    case CogApi.authenticate(client) do
      {:ok, client} ->
        do_enable(client, :proplists.get_value(:bundle, options))
      {:error, error} ->
        display_error(error["error"])
    end
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
