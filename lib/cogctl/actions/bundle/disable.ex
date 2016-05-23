defmodule Cogctl.Actions.Bundle.Disable do
  use Cogctl.Action, "bundle disable"

  alias CogApi.HTTP.Client

  def option_spec() do
    [{:bundle_name, :undefined, :undefined, :string, 'Bundle name (required)'},
     {:verbose, ?v, 'verbose', {:boolean, false}, 'Verbose output'}]
  end

  def run(options, _args,  _config, endpoint) do
    bundle_name = :proplists.get_value(:bundle_name, options)
    verbose = :proplists.get_value(:verbose, options)
    with_authentication(endpoint,
                        &do_disable(&1, bundle_name, verbose))
  end

  defp do_disable(endpoint, bundle_name, verbose) do
    case Client.bundle_enabled_version_by_name(endpoint, bundle_name) do
      {:ok, status} ->
        if status["enabled"] do
          case Client.bundle_disable_version_by_name(endpoint, bundle_name, status["enabled_version"]) do
            {:ok, _} ->
              display_output("Disabled '#{bundle_name}'", verbose)
            {:error, error} ->
              display_error(error)
          end
        else
          display_output("No versions enabled for '#{bundle_name}'.", verbose)
        end
    end
  end
end
