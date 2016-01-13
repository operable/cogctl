defmodule CogctlTest do
  use Support.CliCase

  doctest Cogctl

  test "cogctl" do
    assert run("cogctl") == """
    Usage: cogctl [bootstrap | profiles | bundle list | bundle delete | user list | user show | user create | user update | user delete | group list | group create | group update | group delete | role list | role create | role update | role delete]

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

  test "cogctl user create" do
    output = run("""
    cogctl user create
      --first-name=Kevin
      --last-name=Smith
      --email=kevin@operable.io
      --username=kevsmith
      --password=password
    """)

    assert output =~ ~r"""
    Created user: Kevin Smith \(.*\)
    """

    [_, id] = ~r"""
    Created user: Kevin Smith \((.*)\)
    """ |> Regex.run(output)

    run("cogctl user delete #{id}")
  end

  test "cogctl user update" do
    output = run("""
    cogctl user create
      --first-name=Kevin
      --last-name=Smith
      --email=kevin@operable.io
      --username=kevsmith
      --password=password
    """)

    [_, id] = ~r"""
    Created user: Kevin Smith \((.*)\)
    """ |> Regex.run(output)

    output = run("cogctl user update #{id} --last-name=Smitherino")

    assert output =~ ~r"""
    Updated user: Kevin Smitherino \(#{id}\)
      first_name: Kevin
      last_name: Smitherino
      email_address: kevin@operable.io
      username: kevsmith
    """

    run("cogctl user delete #{id}")
  end

  test "cogctl user delete" do
    output = run("""
    cogctl user create
      --first-name=Kevin
      --last-name=Smith
      --email=kevin@operable.io
      --username=kevsmith
      --password=password
    """)

    [_, id] = ~r"""
    Created user: Kevin Smith \((.*)\)
    """ |> Regex.run(output)

    assert run("cogctl user delete #{id}") =~ ~r"""
    Deleted user: #{id}
    """
  end

  test "cogctl group list" do
    output = run("cogctl group create --name=admin")

    [_, id] = ~r"""
    Created group: admin \((.*)\)
    """ |> Regex.run(output)

    assert run("cogctl group list") =~ ~r"""
    Group: admin \(#{id}\)
    """

    run("cogctl group delete #{id}")
  end

  test "cogctl group create" do
    output = run("cogctl group create --name=admin")

    assert output =~ ~r"""
    Created group: admin \((.*)\)
    """

    [_, id] = ~r"""
    Created group: admin \((.*)\)
    """ |> Regex.run(output)

    run("cogctl group delete #{id}")
  end

  test "cogctl group update" do
    output = run("cogctl group create --name=admin")

    [_, id] = ~r"""
    Created group: admin \((.*)\)
    """ |> Regex.run(output)

    output = run("cogctl group update #{id} --name=ops")

    assert output =~ ~r"""
    Updated group: ops \(#{id}\)
    """

    run("cogctl group delete #{id}")
  end


  test "cogctl group delete" do
    output = run("cogctl group create --name=admin")

    [_, id] = ~r"""
    Created group: admin \((.*)\)
    """ |> Regex.run(output)

    assert run("cogctl group delete #{id}") =~ ~r"""
    Deleted group: #{id}
    """
  end

  test "cogctl role list" do
    output = run("cogctl role create --name=developer")

    [_, id] = ~r"""
    Created role: developer \((.*)\)
    """ |> Regex.run(output)

    assert run("cogctl role list") =~ ~r"""
    Role: developer \(#{id}\)
    """

    run("cogctl role delete #{id}")
  end

  test "cogctl role create" do
    output = run("cogctl role create --name=admin")

    assert output =~ ~r"""
    Created role: admin \((.*)\)
    """

    [_, id] = ~r"""
    Created role: admin \((.*)\)
    """ |> Regex.run(output)

    run("cogctl role delete #{id}")
  end

  test "cogctl role update" do
    output = run("cogctl role create --name=admin")

    [_, id] = ~r"""
    Created role: admin \((.*)\)
    """ |> Regex.run(output)

    output = run("cogctl role update #{id} --name=ops")

    assert output =~ ~r"""
    Updated role: ops \(#{id}\)
    """

    run("cogctl role delete #{id}")
  end


  test "cogctl role delete" do
    output = run("cogctl role create --name=admin")

    [_, id] = ~r"""
    Created role: admin \((.*)\)
    """ |> Regex.run(output)

    assert run("cogctl role delete #{id}") =~ ~r"""
    Deleted role: #{id}
    """
  end
end
