defmodule Support.CliCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      import Support.CliCase
      import Support.CliHelpers
    end
  end

  setup do
    Support.CliHelpers.ensure_started
  end
end
