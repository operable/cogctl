defmodule Cogctl.Actions.Bundle.Versions do
  use Cogctl.Action, "bundle versions"

  alias CogApi.HTTP.Client
  alias Cogctl.Actions.Bundle.Helpers
  alias Cogctl.Table

  @moduledoc """
  List versions for the specified bundle.
  """

  def option_spec do
    [{:bundle_name, :undefined, :undefined, :string, 'The bundle name to list versions for (required)'},
     {:verbose, ?v, 'verbose', {:boolean, false}, 'Verbose output'}]
  end

  def run(options, _args, _config, endpoint) do
    bundle_name = :proplists.get_value(:bundle_name, options)
    verbose = :proplists.get_value(:verbose, options)

    with_authentication(endpoint, &do_versions(&1, bundle_name, verbose))
  end

  defp do_versions(endpoint, bundle_name, verbose) do
    case Client.bundle_version_index_by_name(endpoint, bundle_name) do
      {:ok, bundle_versions} ->
        render(bundle_versions, verbose)
      {:error, error} ->
        display_error(error)
    end
  end

  defp render(bundle_versions, false) do
    headers = ["VERSION", "STATUS"]
    versions = Enum.map(bundle_versions, &([&1.version, Helpers.status(&1)]))

    Table.format([headers] ++ versions)
    |> display_output
  end
  defp render(bundle_versions, true) do
    headers = ["VERSION", "STATUS", "INSTALLED ON", "ID"]
    versions = Enum.map(bundle_versions,
                        &([&1.version,
                           Helpers.status(&1),
                           &1.inserted_at,
                           &1.id]))

    Table.format([headers] ++ versions)
    |> display_output
  end
end
