defmodule CogctlTest do
  use ExUnit.Case
  import Support.CliHelper

  doctest Cogctl

  test "running cogctl" do
    assert run("cogctl") == """
    Usage: cogctl [bootstrap | profiles | bundle list | bundle delete]

           cogctl <action> --help will display action specific help information.
    """
  end
end
