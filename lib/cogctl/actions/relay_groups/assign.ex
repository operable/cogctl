defmodule Cogctl.Actions.RelayGroups.Assign do
  use Cogctl.Action, "relay-groups assign"

  @moduledoc """
  Assigns bundles to relay groups. Requires the group and at least one bundle to
  work properly. Iterates over the list of bundles and assigns them to the relay-
  group. If an error occurs, the operation is aborted and an error message
  returned to the user.

  Usage:
  'cogctl relay-groups assign $RELAYGROUP --bundles=$BUNDLE1,$BUNDLE2,$BUNDLE3'
  """

  def option_spec() do
    [{:relay_group, :undefined, :undefined, {:string, :undefined}, 'Relay Group name (required)'},
     {:bundles, :undefined, 'bundles', {:list, :undefined}, 'Bundle names (required)'}]
  end

  def run(options, _args, _config, endpoint) do
    # At least one bundle is required, so we specify that here
    case convert_to_params(options, option_spec, [relay_group: :required,
                                                  bundles: :required]) do
      {:ok, params} ->
        # The rest of the bundles, if there are any, get appended here.
        with_authentication(endpoint, &do_assign(&1, params))
      {:error, {:missing_params, missing_params}} ->
        display_arguments_error(missing_params)
    end
  end

  defp do_assign(endpoint, params) do
    IO.inspect params.bundles
    case CogApi.HTTP.Client.relay_group_add_bundles_by_name(params.relay_group, params.bundles, endpoint) do
      {:ok, _} ->
        bundle_string = List.wrap(params.bundles)
        |> Enum.join(", ")
        display_output("Assigned '#{bundle_string}' to relay group `#{params.relay_group}`")
      {:error, error} ->
        display_error(error)
    end
  end
end
