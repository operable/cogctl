defmodule Support.CliCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      import Support.CliCase
      import Support.CliHelpers

      @moduletag :external
    end
  end

  setup do
    host = System.get_env("COGCTL_COG_HOST") || "localhost"
    port = System.get_env("COGCTL_COG_PORT") || "4000"
    Support.CliHelpers.ensure_started(host, port)
  end
end
