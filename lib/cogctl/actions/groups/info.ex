defmodule Cogctl.Actions.Groups.Info do
  use Cogctl.Action, "groups info"

  alias Cogctl.Actions.Groups

  def option_spec do
    [{:group, :undefined, :undefined, :string, 'Group name (required)'}]
  end

  def run(options, _args, _config, %{token: nil}=endpoint) do
    with_authentication(endpoint, &run(options, nil, nil, &1))
  end

  def run(options, _args, _config, endpoint) do
    group = Groups.find_by_name(endpoint, :proplists.get_value(:group, options))
    Groups.render(group)
  end

end
