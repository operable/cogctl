defmodule Cogctl.Actions.Relays.Delete do
  use Cogctl.Action, "relays delete"

  def option_spec do
    []
  end

  def run(options, args, _config, %{token: nil}=endpoint) do
    with_authentication(endpoint, &run(options, args, nil, &1))
  end
  def run(_options, [], _config, _endpoint), do: display_arguments_error
  def run(_options, args, _config, endpoint) do
    do_delete(endpoint, args)
  end

  defp do_delete(endpoint, relay_names) do
    Enum.reduce(relay_names, 0, fn(relay_name, acc) ->
      case delete(endpoint, relay_name) do
        :ok -> acc
        _ -> acc + 1
      end
    end)
  end

  defp delete(endpoint, relay_name) do
    case CogApi.HTTP.Client.relay_delete(%{name: relay_name}, endpoint) do
      :ok ->
        display_output("Deleted #{relay_name}")
      {:error, error} ->
        display_error(error)
    end
  end
end
