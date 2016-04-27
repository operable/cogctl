defmodule Cogctl.Actions.Groups.Create do
  use Cogctl.Action, "groups create"

  alias Cogctl.Actions.Groups
  alias CogApi.HTTP.Client

  def option_spec do
    [{:name, :undefined, :undefined, {:string, :undefined}, 'Group name (required)'}]
  end

  def run(options, _args, _config, %{token: nil}=endpoint) do
    with_authentication(endpoint, &run(options, nil, nil, &1))
  end

  def run(options, _args, _config, endpoint) do
    do_create(endpoint, :proplists.get_value(:name, options))
  end

  defp do_create(_endpoint, :undefined), do: display_arguments_error
  defp do_create(endpoint, group_name) do
    case Client.group_create(endpoint, %{name: group_name}) do
      {:ok, group} ->
        Groups.render(group)
      {:error, message} ->
        display_error(message)
    end
  end
end
