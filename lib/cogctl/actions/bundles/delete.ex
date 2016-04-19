defmodule Cogctl.Actions.Bundles.Delete do
  use Cogctl.Action, "bundles delete"

  def option_spec do
    []
  end

  def run(_options, args,  _config, endpoint),
    do: with_authentication(endpoint, &do_delete(&1, args))

  defp do_delete(_endpoint, []) do
    display_arguments_error("bundle")
  end

  defp do_delete(endpoint, bundle_names) when is_list(bundle_names) do
    Enum.reduce_while(bundle_names, :ok, fn bundle_name, _acc ->
      case do_delete(endpoint, bundle_name) do
        :ok ->
          {:cont, :ok}
        :error ->
          {:halt, :error}
      end
    end)
  end

  defp do_delete(endpoint, bundle_name) do
    case CogApi.HTTP.Internal.bundle_delete(endpoint, bundle_name) do
      :ok ->
        display_output("Deleted #{bundle_name}")
      {:error, error} ->
        display_error(error["errors"])
    end
  end
end
