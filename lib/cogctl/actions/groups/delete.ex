defmodule Cogctl.Actions.Groups.Delete do
  use Cogctl.Action, "groups delete"
  alias Cogctl.CogApi

  def option_spec do
    [{:group, :undefined, :undefined, {:string, :undefined}, 'Group name'}]
  end

  def run(options, _args, _config, profile) do
    client = CogApi.new_client(profile)
    case CogApi.authenticate(client) do
      {:ok, client} ->
        do_delete(client, :proplists.get_value(:group, options))
      {:error, error} ->
        IO.puts "#{error["error"]}"
    end
  end

  def do_delete(client, group_name) do
    case CogApi.group_delete(client, group_name) do
      :ok ->
        IO.puts "Deleted #{group_name}"
        :ok
      {:error, resp} ->
        {:error, resp}
    end
  end
end
