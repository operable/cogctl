defmodule Cogctl.Actions.Bundle do
  use Cogctl.Action, "bundle"
  alias Cogctl.Table
  alias CogApi.HTTP.Client
  alias Cogctl.Actions.Bundle.Helpers

  @moduledoc """
  Returns a list of bundles formatted as a table. By default, returns name and
  the enabled version number. Optional 'verbose' flag adds all installed versions
  and the bundle id.

  Show just the enabled or disabled versions with the 'enabled' and 'disabled'
  flags respectively.
  """

  def option_spec do
    [{:verbose, ?v, 'verbose', {:boolean, false}, 'Display additional bundle information'},
     {:enabled, ?e, 'enabled', {:boolean, false}, 'Only list bundles with an enabled version'},
     {:disabled, ?d, 'disabled', {:boolean, false}, 'Only list bundles without an enabled version'}]
  end

  def run(options, _args, _config, endpoint),
    do: with_authentication(endpoint, &do_list(&1, options))

  defp do_list(endpoint, options) do
    case Client.bundle_index(endpoint) do
      {:ok, bundles} ->
        render(bundles, options)
        |> display_output
      {:error, error} ->
        display_error(error["errors"])
    end
  end

  # Renders a table of bundles as:
  #
  # NAME         ENABLED VERSION
  # bundle_name  0.1.0
  #
  # or
  #
  # NAME         ENABLED VERSION  INSTALLED VERSIONS  BUNDLE ID
  # bundle_name  0.1.0            0.0.1, 0.1.0        C52B83F1-1DC6-4131-BCC9-CDF3FF659072
  defp render(bundles, options) do
    enabled = :proplists.get_value(:enabled, options)
    disabled = :proplists.get_value(:disabled, options)
    verbose = :proplists.get_value(:verbose, options)

    headers = if verbose do
      ["NAME", "ENABLED VERSION", "INSTALLED VERSIONS", "BUNDLE ID"]
    else
      ["NAME", "ENABLED VERSION"]
    end

    rows = filter_bundles(bundles, enabled, disabled)
    |> Enum.map(&make_row(&1, verbose))

    Table.format([headers] ++ rows)
  end

  defp filter_bundles(bundles, enabled, disabled) do
    cond do
      enabled and disabled ->
        bundles
      enabled ->
        Enum.filter(bundles, &(Helpers.enabled?(&1)))
      disabled ->
        Enum.filter(bundles, &(not(Helpers.enabled?(&1))))
      true ->
        bundles
    end
  end

  defp make_row(bundle, verbose) do
    if verbose do
      [bundle.name,
       enabled_version(bundle.enabled_version),
       installed_versions(bundle.versions),
       bundle.id]
    else
      [bundle.name,
       enabled_version(bundle.enabled_version)]
    end
  end

  defp enabled_version(nil),
    do: "(disabled)"
  defp enabled_version(bundle_version),
    do: bundle_version.version

  defp installed_versions(versions),
    do: Enum.map_join(versions, ", ", &(&1.version))
end
