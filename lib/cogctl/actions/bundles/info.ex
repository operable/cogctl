defmodule Cogctl.Actions.Bundles.Info do
  use Cogctl.Action, "bundles info"
  alias Cogctl.Actions.Bundles
  alias Cogctl.Table

  def option_spec do
    [{:bundle, :undefined, :undefined, {:string, :undefined}, 'Bundle name (required)'}]
  end

  def run(options, _args, _config, endpoint) do
    with_authentication(endpoint,
                        &do_info(&1, :proplists.get_value(:bundle, options)))
  end

  defp do_info(_endpoint, :undefined) do
    display_error("Missing required arguments")
  end

  defp do_info(endpoint, bundle_name) do
    case CogApi.HTTP.Old.bundle_show(endpoint, bundle_name) do
      {:ok, resp} ->
        bundle = resp["bundle"]

        status = Bundles.enabled_to_status(bundle["enabled"])
        bundle = Map.merge(bundle, %{"status" => status})

        bundle_attrs = for {title, attr} <- [{"ID", "id"}, {"Name", "name"}, {"Status", "status"}, {"Installed", "inserted_at"}] do
          [title, bundle[attr]]
        end

        commands = for command <- bundle["commands"] do
          [command["name"], command["id"]]
        end

        display_output("""
        #{Table.format(bundle_attrs, false)}

        Commands
        #{Table.format([["NAME", "ID"]|commands], true)}
        """ |> String.rstrip)
      {:error, error} ->
        display_error(error["errors"])
    end
  end
end
