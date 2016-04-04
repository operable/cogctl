defmodule Cogctl.Actions.Bundles do
  use Cogctl.Action, "bundles"
  alias Cogctl.Table

  def option_spec do
    []
  end

  def run(_options, _args, _config, endpoint),
    do: with_authentication(endpoint, &do_list/1)

  defp do_list(endpoint) do
    case CogApi.HTTP.Bundles.index(endpoint) do
      {:ok, bundles} ->

        bundle_details = for bundle <- bundles do
          [bundle.name, enabled_to_status(bundle.enabled), bundle.inserted_at]
        end

        display_output(Table.format([["NAME", "STATUS", "INSTALLED"]] ++ bundle_details, true))
      {:error, error} ->
        display_error(error["errors"])
    end
  end

  def enabled_to_status(true), do: "enabled"
  def enabled_to_status(false), do: "disabled"
end
