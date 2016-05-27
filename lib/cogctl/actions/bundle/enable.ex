defmodule Cogctl.Actions.Bundle.Enable do
  use Cogctl.Action, "bundle enable"

  alias CogApi.HTTP.Client

  def option_spec() do
    [{:bundle_name, :undefined, :undefined, :string, 'Bundle name (required)'},
     {:bundle_version, :undefined, :undefined, {:string, :undefined}, 'Bundle version. Defaults to the most recently installed version.'},
     {:verbose, ?v, 'verbose', {:boolean, false}, 'Verbose output'}]
  end

  def run(options, _args,  _config, endpoint) do
    bundle_name = :proplists.get_value(:bundle_name, options)
    bundle_version = :proplists.get_value(:bundle_version, options)
    verbose = :proplists.get_value(:verbose, options)

    with_authentication(endpoint,
                        &do_enable(&1, bundle_name, bundle_version, verbose))
  end

  defp do_enable(endpoint, bundle_name, :undefined, verbose) do
    case Client.bundle_version_index_by_name(endpoint, bundle_name) do
      {:ok, bundle_versions} ->
        latest_version = Enum.max_by(bundle_versions, fn(version) ->
          version.version
        end)

        case Client.bundle_enable_version(endpoint, latest_version.bundle_id, latest_version.id) do
          {:ok, status} ->
            display_output("Enabled '#{bundle_name}' '#{status["enabled_version"]}'", verbose)
          {:error, error} ->
            display_error(error)
        end
      {:error, error} ->
        display_error(error)
    end
  end
  defp do_enable(endpoint, bundle_name, bundle_version, verbose) do
    case Client.bundle_enable_version_by_name(endpoint, bundle_name, bundle_version) do
      {:ok, _} ->
        display_output("Enabled '#{bundle_name}' '#{bundle_version}'", verbose)
      {:error, error} ->
        display_error(error)
    end
  end
end
