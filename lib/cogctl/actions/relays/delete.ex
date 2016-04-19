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
    results = Enum.reduce(relay_names, %{success: [], failure: []}, fn(relay_name, acc) ->
      case delete(endpoint, relay_name) do
        {:ok, name} -> %{acc | success: [name | acc.success]}
        {:error, error} -> %{acc | failure: [error | acc.failure]}
      end
    end)

    if length(results.failure) > 0 do
      display_error(Enum.join(results.failure, ","))
    end
    if length(results.success) > 0 do
      display_output("Deleted '#{Enum.join(results.success, ",")}'")
    end

  end

  defp delete(endpoint, relay_name) do
    case CogApi.HTTP.Client.relay_delete(%{name: relay_name}, endpoint) do
      :ok ->
        {:ok, relay_name}
      {:error, error} ->
        {:error, error}
    end
  end
end
