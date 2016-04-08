defmodule Cogctl.Actions.RelayGroups.Delete do
  use Cogctl.Action, "relay-groups delete"

  def option_spec do
    []
  end

  def run(options, args, _config, %{token: nil}=endpoint),
    do: with_authentication(endpoint, &run(options, args, nil, &1))
  def run(_options, [], _config, _endpoint),
    do: display_arguments_error
  def run(_options, args, _config, endpoint),
    do: do_delete(endpoint, args)

  defp do_delete(endpoint, group_names) do
    Enum.reduce(group_names, 0, fn(group_name, acc) ->
      case delete(endpoint, group_name) do
        :ok -> acc
        _ -> acc + 1
      end
    end)
  end

  defp delete(endpoint, group_name) do
    case CogApi.HTTP.Client.relay_group_delete(%{name: group_name}, endpoint) do
      :ok ->
        display_output("Deleted relay group `#{group_name}`")
      {:error, error} ->
        display_error(error)
    end
  end

end
