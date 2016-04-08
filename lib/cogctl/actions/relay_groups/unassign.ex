defmodule Cogctl.Actions.RelayGroups.Unassign do
  use Cogctl.Action, "relay-groups unassign"

  def option_spec() do
    [{:name, :undefined, :undefined, {:string, :undefined}, 'Relay Group name (required)'},
     {:bundle, :undefined, 'bundle', {:string, :undefined}, 'Bundle name (required)'}]
  end

  def run(options, _args, _config, %{token: nil}=endpoint) do
    with_authentication(endpoint, &run(options, nil, nil, &1))
  end
  def run(options, _args, _config, endpoint) do
    case convert_to_params(options, [bundle: :required,
                                     name: :required]) do
      {:ok, params} ->
        do_unassign(endpoint, params)
      _ ->
        display_arguments_error
    end
  end

  defp do_unassign(endpoint, params) do
    case CogApi.HTTP.Client.relay_group_remove_bundle(%{name: params.name}, %{bundle: params.bundle}, endpoint) do
      {:ok, _} ->
        display_output("Bundle `#{params.bundle}` unassigned from relay group `#{params.name}`")
      {:error, error} ->
        display_error(error)
    end
  end
end
