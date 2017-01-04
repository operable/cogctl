defmodule Cogctl.Actions.Bundle.Info do
  use Cogctl.Action, "bundle info"
  alias CogApi.Resources.Bundle
  alias CogApi.Resources.BundleVersion
  alias CogApi.HTTP.Client
  alias Cogctl.Actions.Bundle.Helpers
  import Cogctl.Actions.Bundle.Helpers, only: [field: 2, value: 2, value: 3]
  alias Cogctl.Table

  @moduledoc """
  Shows information about bundles and bundle versions.
  """

  def option_spec do
    [{:bundle_name, :undefined, :undefined, :string, 'Bundle name (required)'},
     {:bundle_version, :undefined, :undefined, {:string, :undefined}, 'Bundle version'}]
  end

  def run(options, _args, _config, endpoint) do
    bundle_name = :proplists.get_value(:bundle_name, options)
    bundle_version = :proplists.get_value(:bundle_version, options)
    with_authentication(endpoint,
                        &do_info(&1, bundle_name, bundle_version))
  end

  defp do_info(endpoint, bundle_name, :undefined) do
    Client.bundle_show_by_name(endpoint, bundle_name)
    |> render
  end
  defp do_info(endpoint, bundle_name, bundle_version) do
    Client.bundle_version_show_by_name(endpoint, bundle_name, bundle_version)
    |> render
  end

  defp render({:ok, %Bundle{}=bundle}) do
    map = Map.from_struct(bundle)

    table = Enum.reject(
      [field("Bundle ID:",
         value(map, :id)),
       field("Version ID:",
         value(map, [:enabled_version, &from_struct/3, :id])),
       field("Name:",
         value(map, :name)),
       field("Versions:",
         value(map, [:versions, &all/3, &from_struct/3, :version], &Enum.join(&1, ", "))),
       field("Incompatible Versions:",
         value(map, [:incompatible_versions, &all/3, &from_struct/3, :version], &Enum.join(&1, ", "))),
       field("Status:",
         Helpers.status(bundle)),
       field("Enabled Version:",
         value(map, [:enabled_version, &from_struct/3, :version])),
       field("Commands:",
         value(map, [:enabled_version, &from_struct/3, :commands, &all/3, &from_struct/3],
           &Enum.map_join(&1, ", ", fn(cmd) -> cmd.name end))),
       field("Permissions:",
         value(map, [:enabled_version, &from_struct/3, :permissions, &all/3, &from_struct/3],
           &Enum.map_join(&1, ", ", fn(perm) -> "#{perm.bundle}:#{perm.name}" end))),
       field("Relay Groups:",
         value(map, [:relay_groups, &all/3, &from_struct/3, :name], &Enum.join(&1, ", ")))],
      &is_nil/1)

    Table.format(table)
    |> display_output
  end
  defp render({:ok, %BundleVersion{}=bundle_version}) do
    map = Map.from_struct(bundle_version)

    table = Enum.reject(
      [field("Bundle ID:", value(map, :bundle_id)),
       field("Version ID:", value(map, :id)),
       field("Name:", value(map, :name)),
       field("Status:", value(map, :status)),
       field("Enabled Version:", value(map, :version)),
       field("Commands:",
         value(map, [:commands, &all/3, &from_struct/3],
           &Enum.map_join(&1, ", ", fn(cmd) -> cmd.name end))),
       field("Permissions:",
         value(map, [:permissions, &all/3, &from_struct/3],
           &Enum.map_join(&1, ", ", fn(perm) -> "#{perm.bundle}:#{perm.name}" end)))],
     &is_nil/1)

    Table.format(table)
    |> display_output
  end
  defp render({:error, error}) do
    display_error(error)
  end

  defp from_struct(:get, nil, _next),
    do: nil
  defp from_struct(:get, data, next),
    do: Map.from_struct(data) |> next.()

  defp all(:get, nil, _next),
    do: nil
  defp all(:get, data, next),
    do: Enum.map(data, next)
end
