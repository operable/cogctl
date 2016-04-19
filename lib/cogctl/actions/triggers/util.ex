defmodule Cogctl.Actions.Triggers.Util do
  alias CogApi.Resources.Trigger
  import Cogctl.ActionUtil, only: [display_output: 1,
                                   display_error: 1]

  def table(%Trigger{}=t) do
    for {title, attr} <- [{"ID", :id},
                          {"Name", :name},
                          {"Pipeline", :pipeline},
                          {"Enabled", :enabled},
                          {"As User", :as_user},
                          {"Timeout (sec)", :timeout_sec},
                          {"Description", :description},
                          {"Invocation URL", :invocation_url}] do
      table_row(title, Map.fetch!(t, attr))
    end
  end

  defp table_row(title, nil),
    do: [title, ""]
  defp table_row(title, attr),
    do: [title, to_string(attr)]

  def update(endpoint, trigger_name, params) do
    case CogApi.HTTP.Client.trigger_show_by_name(endpoint, trigger_name) do
      {:ok, trigger} ->
         CogApi.HTTP.Client.trigger_update(endpoint, trigger.id, params)
      {:error, _}=error ->
        error
    end
  end

  def set_enabled(endpoint, trigger_name, enabled) when is_boolean(enabled) do
    case update(endpoint, trigger_name, %{enabled: enabled}) do
      {:ok, _updated} ->
        message = if enabled do
           "Enabled trigger #{trigger_name}"
          else
            "Disabled trigger #{trigger_name}"
          end
        display_output(message)
      {:error, error} ->
        display_error(error)
    end
  end

end
