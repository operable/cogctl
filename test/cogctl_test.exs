defmodule CogctlTest do
  use Support.CliCase

  doctest Cogctl

  test "cogctl" do
    assert run("cogctl") == """
    Usage: cogctl [bootstrap | profiles | bundle list | bundle delete | user list | user show]

           cogctl <action> --help will display action specific help information.
    """
  end

  test "cogctl bundle list" do
    assert run("cogctl bundle list") =~ ~r"""
    Bundle: operable \(.*, ns: .*\)
    Installed: .*
    """
  end

  test "cogctl user list" do
    assert run("cogctl user list") =~ ~r"""
    User: Cog Administrator \(.*\)
    """
  end

  test "cogctl user show" do
    users = run("cogctl user list")

    [_, id] = ~r"""
    User: Cog Administrator \((.*)\)
    """ |> Regex.run(users)

    assert run("cogctl user show #{id}") =~ ~r"""
    User: Cog Administrator \(#{id}\)
      first_name: (.*)
      last_name: (.*)
      username: (.*)
      email_address: (.*)
    """
  end
end
