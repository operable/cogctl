defmodule Cogctl.Actions.RelayGroups.Create do
  use Cogctl.Action, "relay-groups create"
  import Cogctl.Actions.RelayGroups.Util, only: [render: 3]

  def option_spec do
    [{:name, :undefined, :undefined, {:string, :undefined}, 'Relay name (required)'}]
  end

  def run(options, _args, _config, %{token: nil}=endpoint) do
    with_authentication(endpoint, &run(options, nil, nil, &1))
  end
  def run(options, _args, _config, endpoint) do
    case convert_to_params(options, [name: :required]) do
      {:ok, params} ->
        do_create(endpoint, params)
      {:error, {:missing_params, missing_params}} ->
        display_arguments_error(missing_params)
    end
  end

  defp do_create(endpoint, params) do
    case CogApi.HTTP.Client.relay_group_create(params, endpoint) do
      {:ok, group} ->
        group_attrs = Enum.map([{"ID", :id}, {"Name", :name}], fn({title, attr}) ->
            [title, Map.fetch!(group, attr)]
            end)
        render(group_attrs, false, "Created relay group `#{group.name}`")
      {:error, error} ->
        display_error(error)
    end
  end
end
