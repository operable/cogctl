defmodule Cogctl.Actions.Groups do
  use Cogctl.Action, "groups"
  alias Cogctl.Table

  def option_spec do
    []
  end

  def run(_options, _args, _config, endpoint),
    do: with_authentication(endpoint, &do_list/1)

  defp do_list(endpoint) do
    case CogApi.HTTP.Old.group_index(endpoint) do
      {:ok, resp} ->
        groups = resp["groups"]
        group_attrs = for group <- groups do
          [group["name"], group["id"]]
        end

        display_output(Table.format([["NAME", "ID"]] ++ group_attrs, true))
      {:error, error} ->
        display_error(error["errors"])
    end
  end

  def render_memberships(%{"members" => %{"users" => users, "groups" => groups, "roles" => roles}}) do
    user_attrs = for user <- users do
      [user["username"], user["id"]]
    end

    group_attrs = for group <- groups do
      [group["name"], group["id"]]
    end

    role_attrs = for role <- roles do
      [role["name"], role["id"]]
    end

    """
    User Memberships
    #{Table.format([["USERNAME", "ID"]] ++ user_attrs, true)}

    Group Memberships
    #{Table.format([["NAME", "ID"]] ++ group_attrs, true)}

    Role Memberships
    #{Table.format([["NAME", "ID"]] ++ role_attrs, true)}
    """ |> String.rstrip
  end
end
