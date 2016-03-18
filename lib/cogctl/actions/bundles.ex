defmodule Cogctl.Actions.Bundles do
  use Cogctl.Action, "bundles"
  alias Cogctl.Table

  def option_spec do
    []
  end

  def run(_options, _args, _config, client),
    do: with_authentication(client, &do_list/1)

  defp do_list(client) do
    case CogApi.bundle_index(client) do
      {:ok, resp} ->
        bundles = for bundle <- resp["bundles"] do
          [bundle["name"], enabled_to_status(bundle["enabled"]), bundle["inserted_at"]]
        end

        display_output(Table.format([["NAME", "STATUS", "INSTALLED"]] ++ bundles, true))
      {:error, error} ->
        display_error(error["error"])
    end
  end

  def enabled_to_status(true), do: "enabled"
  def enabled_to_status(false), do: "disabled"
end
