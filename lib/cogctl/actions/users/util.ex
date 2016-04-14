defmodule Cogctl.Actions.Users.Util do
  alias Cogctl.Table
  alias CogApi.Resources.User
  import Cogctl.ActionUtil , only: [display_output: 1, display_error: 1]

  def render(%User{}=user, groups, roles) do
    user_info = format_user(user)
    groups = format_groups(groups)
    roles = format_roles(roles)

    Table.format(user_info ++ groups ++ roles, false)
    |> display_output
  end

  def render({:error, error}) do
    display_error(error)
  end
  def render(user_info) do
    Table.format(user_info, false)
    |> display_output
  end

  def render({:error, error}, _) do
    display_error(error)
  end
  def render(user_info, sort) do
    Table.format(user_info, sort) |> display_output
  end

  defp format_user(%User{}=user) do
    [["ID", user.id],
     ["Username", user.username],
     ["First Name", user.first_name],
     ["Last Name", user.last_name],
     ["Email", user.email_address]]
  end

  defp format_groups(nil), do: []
  defp format_groups(groups) do
    group_names = Enum.map(groups, &(&1.name))
    |> Enum.sort
    |> Enum.join(",")
    [["Groups", group_names]]
  end

  defp format_roles(nil), do: []
  defp format_roles(roles) do
    role_names =  Enum.map(roles, &(&1.name))
    |> Enum.sort
    |> Enum.join(",")
    [["Roles", role_names]]
  end

end
