defmodule Cogctl.Actions.Groups do
  use Cogctl.Action, "groups"
  alias Cogctl.CogApi
  alias Cogctl.Table

  def option_spec do
    []
  end

  def run(_options, _args, _config, profile) do
    client = CogApi.new_client(profile)
    case CogApi.authenticate(client) do
      {:ok, client} ->
        do_list(client)
      {:error, error} ->
        display_error(error["error"])
    end
  end

  defp do_list(client) do
    case CogApi.group_index(client) do
      {:ok, resp} ->
        groups = resp["groups"]
        group_attrs = for group <- groups do
          [group["name"], group["id"]]
        end

        display_output(Table.format([["NAME", "ID"]] ++ group_attrs))
      {:error, error} ->
        display_error(error["error"])
    end
  end

  def render_memberships(%{"members" => %{"users" => users, "groups" => groups}}) do
    user_attrs = for user <- users do
      [user["username"], user["id"]]
    end

    group_attrs = for group <- groups do
      [group["name"], group["id"]]
    end

    """
    User Memberships
    #{Table.format([["USERNAME", "ID"]] ++ user_attrs)}

    Group Memberships
    #{Table.format([["NAME", "ID"]] ++ group_attrs)}
    """ |> String.rstrip
  end
end
