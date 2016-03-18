defmodule Cogctl.Actions.Bundles.Delete do
  use Cogctl.Action, "bundles delete"

  def option_spec do
    []
  end

  def run(_options, args,  _config, client),
    do: with_authentication(client, &do_delete(&1, args))

  defp do_delete(_client, []) do
    display_arguments_error
  end

  defp do_delete(client, bundle_names) when is_list(bundle_names) do
    Enum.reduce_while(bundle_names, :ok, fn bundle_name, _acc ->
      case do_delete(client, bundle_name) do
        :ok ->
          {:cont, :ok}
        :error ->
          {:halt, :error}
      end
    end)
  end

  defp do_delete(client, bundle_name) do
    case CogApi.bundle_delete(client, bundle_name) do
      :ok ->
        display_output("Deleted #{bundle_name}")
      {:error, error} ->
        display_error(error["error"])
    end
  end
end
