defmodule Cogctl.Actions.RelayGroups.Unassign do
  use Cogctl.Action, "relay-groups unassign"

  @moduledoc """
  Unassigns bundles to relay groups. Requires the group and at least one bundle to
  work properly. Iterates over the list of bundles and removes the assignment from
  the relay-group. If an error occurs, the operation is aborted and an error message
  returned to the user.

  Usage:
  'cogctl relay-groups unassign $RELAYGROUP --bundles=$BUNDLE1,$BUNDLE2,$BUNDLE3'
  """

  def option_spec() do
    [{:relay_group, :undefined, :undefined, :string, 'Relay Group name (required)'},
     {:bundles, :undefined, 'bundles', :list, 'Bundle names (required)'}]
  end

  def run(options, _args, _config, endpoint) do
    params = convert_to_params(options, [:relay_group, :bundles])
    with_authentication(endpoint, &do_unassign(&1, params))
  end

  defp do_unassign(endpoint, params) do
    case CogApi.HTTP.Client.relay_group_remove_bundles_by_name(params.relay_group, params.bundles, endpoint) do
      {:ok, _} ->
        bundle_string = List.wrap(params.bundles)
        |> Enum.join(", ")
        display_output("Unassigned '#{bundle_string}' from relay group `#{params.relay_group}`")
      {:error, error} ->
        display_error(error)
    end
  end
end
