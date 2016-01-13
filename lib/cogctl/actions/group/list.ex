defmodule Cogctl.Actions.Group.List do
  use Cogctl.Action, "group list"
  alias Cogctl.CogApi

  def option_spec do
    []
  end

  def run(_options, _args, _config, profile) do
    client = CogApi.new_client(profile)
    case CogApi.authenticate(client) do
      {:ok, client} ->
        do_list(client)
      {:error, error} ->
        IO.puts "#{error["error"]}"
    end
  end

  def do_list(client) do
    case CogApi.group_list(client) do
      {:ok, resp} ->
        groups = resp["groups"]
        for group <- groups do
          id = group["id"]
          name = group["name"]
          IO.puts "Group: #{name} (#{id})"
        end
        :ok
      {:error, resp} ->
        {:error, resp}
    end
  end
end
