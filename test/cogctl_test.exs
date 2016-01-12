defmodule CogctlTest do
  use Support.CliCase

  doctest Cogctl

  test "cogctl" do
    assert run("cogctl") == """
    Usage: cogctl [bootstrap | profiles | bundle list | bundle delete]

           cogctl <action> --help will display action specific help information.
    """
  end

  test "cogctl bundle list" do
    assert run("cogctl bundle list") =~ Regex.compile!("""
    Bundle: operable (.*, ns: .*)
    Installed: .*
    """)
  end
end
