defmodule Cogctl.Actions.Bundle.Versions do
  use Cogctl.Action, "bundle versions"

  alias CogApi.HTTP.Client
  alias Cogctl.Table

  @moduledoc """
  List versions for the specified bundle.
  """

  def option_spec do
    [{:bundle_name, :undefined, :undefined, {:string, nil}, 'The bundle name to list versions for. (Not specifying a bundle will list all versions across all bundles)'},
     {:incompatible, ?x, 'incompatible', {:boolean, false}, 'Only list incompatible bundles'},
     {:verbose, ?v, 'verbose', {:boolean, false}, 'Verbose output'}]
  end

  def run(options, _args, _config, endpoint) do
    bundle_name = :proplists.get_value(:bundle_name, options)
    incompatible = :proplists.get_value(:incompatible, options)
    verbose = :proplists.get_value(:verbose, options)

    with_authentication(endpoint, &do_versions(&1, bundle_name, incompatible, verbose))
  end

  # If a bundle name isn't specified we return all versions
  defp do_versions(endpoint, nil, incompatible, verbose) do
    case Client.bundle_index(endpoint) do
      {:ok, bundles} ->
        bundle_versions = Enum.flat_map(bundles, fn(bundle) ->
          {:ok, versions} = Client.bundle_version_index(endpoint, bundle.id)
          maybe_filter(versions, incompatible)
        end)

        render(bundle_versions, verbose)
      {:error, error} ->
        display_error(error)
    end
  end
  defp do_versions(endpoint, bundle_name, incompatible, verbose) do
    case Client.bundle_version_index_by_name(endpoint, bundle_name) do
      {:ok, bundle_versions} ->
        maybe_filter(bundle_versions, incompatible)
        |> render(verbose)
      {:error, error} ->
        display_error(error)
    end
  end

  defp render(bundle_versions, false) do
    headers = ["BUNDLE", "VERSION", "STATUS"]
    versions = Enum.map(bundle_versions, &([&1.name, &1.version, &1.status]))

    Table.format([headers] ++ versions)
    |> display_output
  end
  defp render(bundle_versions, true) do
    headers = ["BUNDLE", "VERSION", "STATUS", "INSTALLED ON", "ID"]
    versions = Enum.map(bundle_versions,
                        &([&1.name,
                           &1.version,
                           &1.status,
                           &1.inserted_at,
                           &1.id]))

    Table.format([headers] ++ versions)
    |> display_output
  end

  defp maybe_filter(versions, true),
    # Only return versions that are incompatible
    do: Enum.filter(versions, &(&1.incompatible))
  defp maybe_filter(versions, false),
    do: versions

end
