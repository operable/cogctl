defmodule Cogctl.Actions.RelayGroups.Assign do
  use Cogctl.Action, "relay-groups assign"

  @moduledoc """
  Assigns bundles to relay groups. Requires the group and at least one bundle to
  work properly. Iterates over the list of bundles and assigns them to the relay-
  group. If an error occurs, the operation is aborted and an error message
  returned to the user.

  Usage:
  'cogctl relay-groups assign $RELAYGROUP $BUNDLE1 $BUNDLE2 $BUNDLE3'
  """

  def option_spec() do
    [{:relay_group, :undefined, :undefined, {:string, :undefined}, 'Relay Group name (required)'},
     # Technically this will just be the first relay
     # This command just uses positional options. The first argument is the name
     # of the relay group. Anything after that is considered a bundle.
     # getopt will only assign the first item in the bundle list to the bundles
     # option, but that's fine since we only require one. The rest of the bundles
     # will come in as arguments. We can stick them all together before calling
     # the api.
     {:bundles, :undefined, :undefined, {:string, :undefined}, 'Bundle names (required)'}]
  end

  def run(options, args, _config, endpoint) do
    # At least one bundle is required, so we specify that here
    case convert_to_params(options, [relay_group: :required,
                                     bundles: :required]) do
      {:ok, params} ->
        # The rest of the bundles, if there are any, get appended here.
        params = %{params | bundles: [params.bundles | args]}
        with_authentication(endpoint, &do_assign(&1, params))
      {:error, {:missing_params, missing_params}} ->
        display_arguments_error(missing_params)
    end
  end

  defp do_assign(endpoint, params) do
    case CogApi.HTTP.Client.relay_group_add_bundles(%{name: params.relay_group}, %{bundles: params.bundles}, endpoint) do
      {:ok, _} ->
        display_output("Assigned '#{Enum.join(params.bundles, ", ")}' to relay group `#{params.relay_group}`")
      {:error, error} ->
        display_error(error)
    end
  end
end
