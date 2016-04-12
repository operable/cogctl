defmodule CogctlTest do
  use Support.CliCase

  doctest Cogctl

  @scratch_dir Path.join([File.cwd!, "test", "scratch"])
  @template_dir Path.join(@scratch_dir, "templates")

  defp pre_bundle_create do
    # Make sure the bundle doesn't exist first
    run("cogctl bundles delete testfoo")

    # Create some templates
    Enum.each(["slack", "hipchat"], fn(adapter) ->
      template_dir = Path.join(@template_dir, adapter)
      File.mkdir_p!(template_dir)

      Enum.each(["foo", "bar"], &File.write!(Path.join(template_dir, "#{&1}.mustache"), "{{#{&1}}}"))
    end)

    # Create a config file
    config = """
    ---
    name: testfoo
    version: 0.0.1
    commands:
      bar:
        executable: /bin/foobar
    """
    File.write!(Path.join(@scratch_dir, "config.yaml"), config)
  end

  defp cleanup do
    # Remove the scratch dir when we're finished
    File.rm_rf!(@scratch_dir)
  end

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
    pre_bundle_create

    assert run("cogctl bundles create --templates #{@template_dir} #{Path.join(@scratch_dir, "config.yaml")}") =~ ~r"""
    Created 'testfoo' bundle
    """

    cleanup

    assert run("cogctl bundles delete testfoo") =~ ~r"""
    Deleted testfoo
    """

    assert run("cogctl bundles") =~ ~r"""
    NAME      STATUS   INSTALLED
    operable  enabled  .*
    """

    assert run("cogctl bundles info") =~ ~r"""
    ERROR: "Missing required arguments"
    """

    assert run("cogctl bundles info operable") =~ ~r"""
    ID         .*
    Name       operable
    Status     enabled
    Installed  .*

    Commands
    NAME         ID
    alias        .*
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
    sleep        .*
    sort         .*
    sum          .*
    table        .*
    thorn        .*
    unique       .*
    wc           .*
    which        .*
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

    Groups
    NAME  ID
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

    output = run("""
    cogctl users create
      --email=rrobin@operable.io
      --username=rrobin
      --password=password
    """)

    assert output =~ ~r"""
    Created rrobin

    ID          .*
    Username    rrobin
    First Name
    Last Name
    Email       rrobin@operable.io
    """

    assert run("cogctl users delete jfrost") =~ ~r"""
    Deleted jfrost
    """

    assert run("cogctl users delete rrobin") =~ ~r"""
    Deleted rrobin
    """
  end

  test "cogctl groups" do
    assert run("cogctl groups create admin") =~ ~r"""
    Created group admin

    ID     .*
    Name   admin
    Users
    Roles
    """

    assert run("cogctl groups create ops") =~ ~r"""
    Created group ops

    ID     .*
    Name   ops
    Users
    Roles
    """

    assert run("cogctl groups") =~ ~r"""
    NAME   ID
    admin  .*
    ops    .*
    """

    assert run("cogctl groups rename ops devops") =~ ~r"""
    Renamed group ops to devops

    ID     .*
    Name   devops
    Users
    Roles
    """

    assert run("cogctl groups add admin --email=cog@localhost") =~ ~r"""
    Added cog@localhost to admin

    ID     .*
    Name   admin
    Users  cog@localhost
    Roles
    """

    assert run("cogctl roles create tester") =~ ~r"""
    Created tester

    ID    .*
    Name  tester
    """

    assert run("cogctl roles grant tester --group=admin") =~ ~r"""
    Granted tester to admin
    """

    assert run("cogctl groups info admin") =~ ~r"""
    ID     .*
    Name   admin
    Users  cog@localhost
    Roles  tester
    """

    assert run("cogctl groups remove admin --email=cog@localhost") =~ ~r"""
    Removed cog@localhost from admin

    ID     .*
    Name   admin
    Users
    Roles  tester
    """

    assert run("cogctl roles revoke --group=admin tester") =~ ~r"""
    Revoked tester from admin
    """

    assert run("cogctl groups delete devops") =~ ~r"""
    Deleted devops
    """

    assert run("cogctl groups delete admin") =~ ~r"""
    Deleted admin
    """

    assert run("cogctl roles delete tester") =~ ~r"""
    Deleted tester
    """
  end

  test "cogctl roles" do
    assert run("cogctl roles create developer") =~ ~r"""
    Created developer

    ID    .*
    Name  developer
    """

    assert run("cogctl roles") =~ ~r"""
    NAME       ID
    developer  .*
    """

    assert run("cogctl roles rename developer support") =~ ~r"""
    Renamed developer to support

    ID    .*
    Name  support
    """

    assert run("cogctl groups create helpdesk") =~ ~r"""
    Created group helpdesk

    ID     .*
    Name   helpdesk
    Users
    Roles
    """

    assert run("cogctl roles grant support --group=helpdesk") =~ ~r"""
    Granted support to helpdesk
    """

    assert run("cogctl roles revoke support --group=helpdesk") =~ ~r"""
    Revoked support from helpdesk
    """

    assert run("cogctl groups delete helpdesk") =~ ~r"""
    Deleted helpdesk
    """

    assert run("cogctl roles delete support") =~ ~r"""
    Deleted support
    """
  end


  test "cogctl permissions" do
    assert run("cogctl permissions") =~ ~r"""
    NAMESPACE  NAME                ID
    operable   manage_commands     .*
    operable   manage_groups       .*
    operable   manage_permissions  .*
    operable   manage_relays       .*
    operable   manage_roles        .*
    operable   manage_triggers     .*
    operable   manage_users        .*
    """

    assert run("cogctl permissions create site:echo") =~ ~r"""
    Created site:echo
    """

    assert run("cogctl roles create developer") =~ ~r"""
    Created developer

    ID    .*
    Name  developer
    """

    assert run("cogctl permissions grant site:echo --role=developer") =~ ~r"""
    Granted site:echo to developer
    """

    assert run("cogctl permissions --role=developer") =~ ~r"""
    NAMESPACE  NAME  ID
    site       echo  .*
    """

    assert run("cogctl roles info developer") =~ ~r"""
    NAME       ID
    developer  .*

    Permissions
    NAMESPACE  NAME  ID
    site       echo  .*
    """

    assert run("cogctl permissions revoke site:echo --role=developer") =~ ~r"""
    Revoked site:echo from developer
    """

    assert run("cogctl permissions delete site:echo") =~ ~r"""
    Deleted site:echo
    """

    assert run("cogctl roles delete developer") =~ ~r"""
    Deleted developer
    """
  end

  test "cogctl rules" do
    assert run("cogctl rules operable:test") =~ ~r"""
    ERROR: "No rules for command found"
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
    assert run("cogctl chat-handles create --user=admin --chat-provider=null --handle=admininator") =~ ~r"""
    Created admininator for null chat provider
    """

    assert run("cogctl chat-handles") =~ ~r"""
    USER   CHAT PROVIDER  HANDLE
    admin  null           admininator
    """

    assert run("cogctl chat-handles delete --user=admin --chat-provider=null") =~ ~r"""
    Deleted chat handle owned by admin for null chat provider
    """

    assert run("cogctl chat-handles") =~ ~r"""
    USER  CHAT PROVIDER  HANDLE
    """
  end

  test "cogctl relays" do
    assert run("cogctl relays") =~ ~r"""
    NAME  STATUS  CREATED  ID
    """

    assert run("cogctl relays create test-relay --token=hola --description='Hola, Como estas'") =~ ~r"""
    Created test-relay

    ID    .*
    Name  test-relay
    """

    assert run("cogctl relays enable test-relay") =~ ~r"""
    Enabled test-relay
    """

    assert run("cogctl relays info test-relay") =~ ~r"""
    Name           test-relay
    ID             .*
    Status         enabled
    Creation Time  .*
    Description    Hola, Como estas

    Relay Groups
    NAME  ID
    """

    assert run("cogctl relays disable test-relay") =~ ~r"""
    Disabled test-relay
    """

    assert run("cogctl relays update test-relay --description='Hello, there'") =~ ~r"""
    Updated test-relay

    Name           test-relay
    ID             .*
    Status         disabled
    Creation Time  .*
    Description    Hello, there

    Relay Groups
    NAME  ID
    """

    assert run("cogctl relays delete test-relay mimimi") =~ ~r"""
    Deleted test-relay
    ERROR: The relay `mimimi` could not be deleted: Resource not found
    Error: 1
    """

  end
end
