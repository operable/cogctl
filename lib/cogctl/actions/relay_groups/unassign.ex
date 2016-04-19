defmodule Cogctl.Actions.RelayGroups.Unassign do
  use Cogctl.Action, "relay-groups unassign"

  @moduledoc """
  Unassigns bundles to relay groups. Requires the group and at least one bundle to
  work properly. Iterates over the list of bundles and removes the assignment from
  the relay-group. If an error occurs, the operation is aborted and an error message
  returned to the user.
  """

  def option_spec() do
    [{:relay_group, :undefined, :undefined, {:string, :undefined}, 'Relay Group name (required)'},
     # Technically this will just be the first bundle
     {:bundles, :undefined, :undefined, {:string, :undefined}, 'Bundle names (required)'}]
  end

  def run(options, args, _config, endpoint) do
    # At least one bundle is required, so we specify that here
    case convert_to_params(options, [relay_group: :required,
                                     bundles: :required]) do
      {:ok, params} ->
        # The rest of the bundles, if there are any, get appended here.
        params = %{params | bundles: [params.bundles | args]}
        with_authentication(endpoint, &do_unassign(&1, params))
      {:error, {:missing_params, missing_params}} ->
        display_arguments_error(missing_params)
    end
  end

  defp do_unassign(endpoint, params) do
    case CogApi.HTTP.Client.relay_group_remove_bundles(%{name: params.relay_group}, %{bundles: params.bundles}, endpoint) do
      {:ok, _} ->
        display_output("Unassigned '#{Enum.join(params.bundles, ", ")}' from relay group `#{params.relay_group}`")
      {:error, error} ->
        display_error(error)
    end
  end
end
