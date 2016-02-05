defmodule CogctlTest do
  use Support.CliCase

  doctest Cogctl

  test "cogctl" do
    help_text = String.strip(run("cogctl"))
    display_names = Cogctl.Optparse.action_display_names()
    more_help_text = "cogctl <action> --help will display action specific help information."
    for name <- display_names do
      assert String.contains?(help_text, name)
    end
    assert String.ends_with?(help_text, more_help_text)
  end

  test "cogctl bundles" do
    assert run("cogctl bundles") =~ ~r"""
    NAME      STATUS   INSTALLED
    operable  enabled  .*
    """

    assert run("cogctl bundles info") =~ ~r"""
    ERROR: Missing required arguments
    """

    assert run("cogctl bundles info operable") =~ ~r"""
    ID         .*
    Name       operable
    Status     enabled
    Installed  .*

    Commands
    NAME         ID
    bundle       .*
    echo         .*
    filter       .*
    greet        .*
    group        .*
    help         .*
    max          .*
    min          .*
    permissions  .*
    raw          .*
    role         .*
    rules        .*
    seed         .*
    sort         .*
    sum          .*
    table        .*
    thorn        .*
    unique       .*
    wc           .*
    """
  end

  test "cogctl users" do
    assert run("cogctl users") =~ ~r"""
    USERNAME  FULL NAME
    admin     Cog Administrator
    """

    assert run("cogctl users info admin") =~ ~r"""
    ID          .*
    Username    admin
    First Name  Cog
    Last Name   Administrator
    Email       cog@localhost
    """

    output = run("""
    cogctl users create
      --first-name=Jack
      --last-name=Frost
      --email=jfrost@operable.io
      --username=jfrost
      --password=password
    """)

    assert output =~ ~r"""
    Created jfrost

    ID          .*
    Username    jfrost
    First Name  Jack
    Last Name   Frost
    Email       jfrost@operable.io
    """

    assert run("""
    cogctl users update jfrost
      --last-name=Smitherino
    """) =~ ~r"""
    Updated jfrost

    ID          .*
    Username    jfrost
    First Name  Jack
    Last Name   Smitherino
    Email       jfrost@operable.io
    """

    assert run("cogctl users delete jfrost") =~ ~r"""
    Deleted jfrost
    """
  end

  test "cogctl groups" do
    assert run("cogctl groups create --name=admin") =~ ~r"""
    Created admin

    ID    .*
    Name  admin
    """

    assert run("cogctl groups create --name=ops") =~ ~r"""
    Created ops

    ID    .*
    Name  ops
    """

    assert run("cogctl groups") =~ ~r"""
    NAME   ID
    admin  .*
    ops    .*
    """

    assert run("cogctl groups update ops --name=devops") =~ ~r"""
    Updated ops

    ID    .*
    Name  devops
    """

    assert run("cogctl groups add admin --user=admin") =~ ~r"""
    Added admin to admin

    User Memberships
    USERNAME  ID
    admin     .*

    Group Memberships
    NAME  ID
    """

    assert run("cogctl groups add admin --group=devops") =~ ~r"""
    Added devops to admin

    User Memberships
    USERNAME  ID
    admin     .*

    Group Memberships
    NAME    ID
    devops  .*
    """

    assert run("cogctl groups info admin") =~ ~r"""
    ID    .*
    Name  admin

    User Memberships
    USERNAME  ID
    admin     .*

    Group Memberships
    NAME    ID
    devops  .*
    """

    assert run("cogctl groups remove admin --user=admin") =~ ~r"""
    Removed admin from admin

    User Memberships
    USERNAME  ID

    Group Memberships
    NAME    ID
    devops  .*
    """

    assert run("cogctl groups delete devops") =~ ~r"""
    Deleted devops
    """

    assert run("cogctl groups delete admin") =~ ~r"""
    Deleted admin
    """
  end

  test "cogctl roles" do
    assert run("cogctl roles create --name=developer") =~ ~r"""
    Created developer

    ID    .*
    Name  developer
    """

    assert run("cogctl roles") =~ ~r"""
    NAME       ID
    developer  .*
    """

    assert run("cogctl roles update developer --name=support") =~ ~r"""
    Updated developer

    ID    .*
    Name  support
    """

    assert run("cogctl roles grant support --user=admin") =~ ~r"""
    Granted support to admin
    """

    assert run("cogctl roles revoke support --user=admin") =~ ~r"""
    Revoked support from admin
    """

    assert run("cogctl roles delete support") =~ ~r"""
    Deleted support
    """
  end

  test "cogctl permissions" do
    assert run("cogctl permissions") =~ ~r"""
    NAME                         ID
    operable:manage_commands     .*
    operable:manage_groups       .*
    operable:manage_permissions  .*
    operable:manage_roles        .*
    operable:manage_users        .*
    """

    assert run("cogctl permissions create site:echo") =~ ~r"""
    Created site:echo
    """

    assert run("cogctl permissions grant site:echo --user=admin") =~ ~r"""
    Granted site:echo to admin
    """

    assert run("cogctl groups create --name=ops") =~ ~r"""
    Created ops

    ID    .*
    Name  ops
    """

    assert run("cogctl permissions grant site:echo --group=ops") =~ ~r"""
    Granted site:echo to ops
    """

    assert run("cogctl permissions --group=ops") =~ ~r"""
    NAME       ID
    site:echo  .*
    """

    assert run("cogctl permissions revoke site:echo --user=admin") =~ ~r"""
    Revoked site:echo from admin
    """

    assert run("cogctl permissions delete site:echo") =~ ~r"""
    Deleted site:echo
    """

    assert run("cogctl groups delete ops") =~ ~r"""
    Deleted ops
    """
  end

  test "cogctl rules" do
    assert run("cogctl rules operable:test") =~ ~r"""
    ERROR: No rules for command found
    """

    # Set up the permission
    run("cogctl permissions create site:test")

    assert run("cogctl rules create --rule-text='when command is operable:echo must have site:test'") =~ ~r"""
    Created .*

    ID         .*
    Rule Text  when command is operable:echo must have site:test
    """

    expected = ~r"""
    ID                                    COMMAND        RULE TEXT
    (?<id>.*)  operable:echo  when command is operable:echo must have site:test
    """
    m = Regex.named_captures(expected, run("cogctl rules operable:echo"))

    assert run("cogctl rules delete #{m["id"]}") =~ ~r"""
    Deleted .*
    """

    # Clean up the permission after we are done
    assert run("cogctl permissions delete site:test") =~ ~r"""
    Deleted site:test
    """
  end

  test "cogctl chat-handles" do
    assert run("cogctl chat-handles create --user=admin --chat-provider=Slack --handle=admininator") =~ ~r"""
    Created admininator for Slack chat provider
    """

    assert run("cogctl chat-handles") =~ ~r"""
    USER   CHAT PROVIDER  HANDLE
    admin  Slack          admininator
    """

    assert run("cogctl chat-handles delete --user=admin --chat-provider=Slack") =~ ~r"""
    Deleted chat handle owned by admin for Slack chat provider
    """

    assert run("cogctl chat-handles") =~ ~r"""
    USER  CHAT PROVIDER  HANDLE
    """
  end
end
