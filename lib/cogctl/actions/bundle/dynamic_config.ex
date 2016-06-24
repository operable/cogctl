defmodule Cogctl.Actions.Bundle.DynamicConfig do
  use Cogctl.Action, "dynamic-config"

  require Cogctl.Actions.Bundle.DynamicConfig.Info

  alias Cogctl.Actions.Bundle.DynamicConfig.Info

  defdelegate option_spec, to: Info

  defdelegate run(options, args, config, endpoint), to: Info
end
