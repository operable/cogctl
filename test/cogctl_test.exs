defmodule CogctlTest do
  use Support.CliCase

  doctest Cogctl

  test "cogctl" do
    assert run("cogctl") == """
    Usage: cogctl [bootstrap | profiles | bundle list | bundle delete | user list]

           cogctl <action> --help will display action specific help information.
    """
  end

  test "cogctl bundle list" do
    assert run("cogctl bundle list") =~ Regex.compile!("""
    Bundle: operable (.*, ns: .*)
    Installed: .*
    """)
  end

  test "cogctl user list" do
    assert run("cogctl user list") =~ Regex.compile!("""
    User: Cog Administrator (.*)
    """)
  end
end
