defmodule Cogctl.Actions.Triggers.Util do
  alias CogApi.Resources.Trigger

  def table(%Trigger{}=t) do
    for {title, attr} <- [{"ID", :id},
                          {"Name", :name},
                          {"Pipeline", :pipeline} ,
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

end
