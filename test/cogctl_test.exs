defmodule CogctlTest do
  use Support.CliCase

  doctest Cogctl

  @scratch_dir Path.join([File.cwd!, "test", "scratch"])
  @template_dir Path.join(@scratch_dir, "templates")

  defp pre_bundle_create(name) do
    # Make sure the bundle doesn't exist first
    run("cogctl bundles delete #{name}")

    # Create some templates
    File.mkdir_p!(@template_dir)
    Enum.each(["foo", "bar"],
              &File.write!(Path.join(@template_dir, "#{&1}.greenbar"),
                           "Lorem ipsum #{&1}"))

    # Create a config file
    config = """
    ---
    name: #{name}
    version: 0.0.1
    cog_bundle_version: 5
    description: "Does stuff"
    commands:
      bar:
        executable: /bin/foobar
        rules:
        - "allow"
    """
    File.write!(Path.join(@scratch_dir, "#{name}.yaml"), config)
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

  test "cogctl users" do
    assert run("cogctl users") =~ ~r"""
    USERNAME  FULL NAME          EMAIL_ADDRESS
    admin     Cog Administrator  cog@localhost
    """

    assert run("cogctl users info admin") =~ ~r"""
    ID          .*
    Username    admin
    First Name  Cog
    Last Name   Administrator
    Email       cog@localhost
    """

    run("cogctl groups create mememe")
    run("cogctl groups add mememe --user=admin")
    run("cogctl roles create mimimi")
    run("cogctl roles grant mimimi --group=cog-admin")

    assert run("cogctl users info admin --groups") =~ ~r"""
    ID          .*
    Username    admin
    First Name  Cog
    Last Name   Administrator
    Email       cog@localhost
    Groups      cog-admin,mememe
    """

    assert run("cogctl users info admin --roles") =~ ~r"""
    ID          .*
    Username    admin
    First Name  Cog
    Last Name   Administrator
    Email       cog@localhost
    Roles       cog-admin,mimimi
    """

    assert run("cogctl users info admin --groups --roles") =~ ~r"""
    ID          .*
    Username    admin
    First Name  Cog
    Last Name   Administrator
    Email       cog@localhost
    Groups      cog-admin,mememe
    Roles       cog-admin,mimimi
    """

    run("cogctl roles revoke mimimi --group=cog-admin")
    run("cogctl roles delete mimimi")
    run("cogctl groups remove mememe --user=admin")
    run("cogctl groups delete mememe")

    output = run("""
    cogctl users create
      --first-name=Jack
      --last-name=Frost
      --email=jfrost@operable.io
      --username=jfrost
      --password=password
    """)

    assert output =~ ~r"""
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
    ID     .*
    Name   admin
    Users
    Roles
    """

    assert run("cogctl groups create ops") =~ ~r"""
    ID     .*
    Name   ops
    Users
    Roles
    """
    assert run("cogctl groups") =~ ~r"""
    NAME       ID
    admin      .*
    cog-admin  .*
    ops        .*
    """

    assert run("cogctl groups rename ops devops") =~ ~r"""
    Renamed group ops to devops

    ID     .*
    Name   devops
    Users
    Roles
    """

    assert run("cogctl groups add admin --user=admin") =~ ~r"""
    Added admin to admin

    ID     .*
    Name   admin
    Users  admin
    Roles
    """

    assert run("cogctl roles create tester") =~ ~r"""
    ID    .*
    Name  tester
    """

    assert run("cogctl roles grant tester --group=admin") =~ ~r"""
    Granted tester to admin
    """

    assert run("cogctl groups info admin") =~ ~r"""
    ID     .*
    Name   admin
    Users  admin
    Roles  tester
    """

    assert run("cogctl groups remove admin --user=admin") =~ ~r"""
    Removed admin from admin

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
    # Make sure the role doesn't exist
    run("cogctl roles delete developer")

    assert run("cogctl roles create developer") =~ ~r"""
    ID    .*
    Name  developer
    """

    assert run("cogctl roles") =~ ~r"""
    NAME       ID
    cog-admin  .*
    developer  .*
    """

    assert run("cogctl roles rename developer support") =~ ~r"""
    Renamed developer to support

    ID    .*
    Name  support
    """

    assert run("cogctl groups create helpdesk") =~ ~r"""
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
    assert run("cogctl permissions") =~ table_string("""
    BUNDLE     NAME                ID
    operable   manage_commands     .*
    operable   manage_groups       .*
    operable   manage_permissions  .*
    operable   manage_relays       .*
    operable   manage_roles        .*
    operable   manage_triggers     .*
    operable   manage_users        .*
    """)

    # Make sure the permission doesn't exist first
    run("cogctl permissions delete site:echo")

    assert run("cogctl permissions create site:echo") =~ ~r"""
    ID      .*
    Bundle  site
    Name    echo
    """

    # Make sure the role doesn't exist
    run("cogctl roles delete developer")

    assert run("cogctl roles create developer") =~ ~r"""
    ID    .*
    Name  developer
    """

    assert run("cogctl permissions grant site:echo --role=developer") =~ ~r"""
    Granted site:echo to developer
    """

    assert run("cogctl permissions --role=developer") =~ ~r"""
    BUNDLE  NAME  ID
    site    echo  .*
    """

    assert run("cogctl roles info developer") =~ ~r"""
    ID:    .*
    Name:  developer
    """

    run("cogctl permissions create site:code")
    run("cogctl permissions grant site:code --role=developer")
    run("cogctl groups create your_land")
    run("cogctl groups create my_land")
    run("cogctl roles grant developer --group=your_land")
    run("cogctl roles grant developer --group=my_land")

    assert run("cogctl roles info developer --permissions") =~ ~r"""
    ID:           .*
    Name:         developer
    Permissions:  site:code,site:echo
    """

    assert run("cogctl roles info developer --groups") =~ ~r"""
    ID:      .*
    Name:    developer
    Groups:  my_land,your_land
    """

    assert run("cogctl roles info developer --groups --permissions") =~ ~r"""
    ID:           .*
    Name:         developer
    Permissions:  site:code,site:echo
    Groups:       my_land,your_land
    """

    run("cogctl permissions revoke site:code --role=developer")
    run("cogctl permissions delete site:code")
    run("cogctl roles revoke developer --group=your_land")
    run("cogctl roles revoke developer --group=my_land")
    run("cogctl groups delete your_land")
    run("cogctl groups delete my_land")

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
    cogctl: ERROR: \"Command operable:test not found\"
    """

    # Set up the permission
    run("cogctl permissions create site:test")

    # Remove default rule from echo
    initial_expected = ~r"""
    ID                                    COMMAND        RULE TEXT
    (?<id>.*)  operable:echo  when command is operable:echo allow
    """
    initial = Regex.named_captures(initial_expected, run("cogctl rules operable:echo"))
    assert run("cogctl rules delete #{initial["id"]}") =~ ~r"""
    Deleted .*
    """

    # Add new rule
    assert run("cogctl rules create --rule-text='when command is operable:echo must have site:test'") =~ ~r"""
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

    # Add the original rule back
    assert run("cogctl rules create --rule-text='when command is operable:echo allow'") =~ ~r"""
    ID         .*
    Rule Text  when command is operable:echo allow
    """
  end

  test "cogctl chat-handles" do
    assert run("cogctl chat-handles create --user=admin --chat-provider=slack --handle=botci") =~ ~r"""
    ID             .*
    User           admin
    Chat Provider  slack
    Handle         botci
    """

    assert run("cogctl chat-handles") =~ ~r"""
    USER   CHAT PROVIDER  HANDLE
    admin  slack          botci
    """

    assert run("cogctl chat-handles delete --user=admin --chat-provider=slack") =~ ~r"""
    Deleted chat handle owned by admin for slack chat provider
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
    ID      .*
    Name    test-relay
    Status  disabled
    """

    assert run("cogctl relays create test-relay2 --enable --token=hola --description='Hola, mi amigo'") =~ ~r"""
    ID      .*
    Name    test-relay2
    Status  enabled
    """
    run("cogctl relays delete test-relay2")

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
    Deleted 'test-relay'
    cogctl: ERROR: "The relay `mimimi` could not be deleted: Resource not found for: 'relays'"
    """

    run("cogctl relay-groups create mygroup")

    assert run("cogctl relays create --enable --groups=group,mygroup test-relay --token=hola") =~ ~r"""
    ID      .*
    Name    test-relay
    Status  enabled

    Adding 'test-relay' to relay group 'group': Error. Resource not found for: 'relay_groups'
    Adding 'test-relay' to relay group 'mygroup': Ok.
    """

    run("cogctl relays delete test-relay")
    run("cogctl relay-groups delete mygroup")
  end

  test "cogctl relay-groups" do
    assert run("cogctl relay-groups") =~ ~r"""
    NAME  CREATED  ID
    """

    assert run("cogctl relay-groups create myrelays") =~ ~r"""
    ID    .*
    Name  myrelays
    """

    run("cogctl relays create test-relay --token=hola")
    run("cogctl relays create my-test --token=hola")

    assert run("cogctl relay-groups add myrelays --relays=test-relay") =~ ~r"""
    Added 'test-relay' to relay group 'myrelays'
    """

    assert run("cogctl relay-groups info myrelays") =~ ~r"""
    Name           myrelays
    ID             .*
    Creation Time  .*

    Relays
    NAME        ID
    test-relay  .*

    Bundles
    NAME  ID
    """

    run("cogctl relay-groups add myrelays --relays=my-test ")

    assert run("cogctl relay-groups remove myrelays --relays=test-relay ") =~ ~r"""
    Removed 'test-relay' from relay group 'myrelays'
    """

    assert run("cogctl relay-groups remove myrelays --relays=my-test ") =~ ~r"""
    Removed 'my-test' from relay group 'myrelays'

    NOTE: There are no more relays in this group.
    """

    bundle_names = Enum.map(1..3, &"bundle#{&1}")
    Enum.each(bundle_names, fn(name) ->
      pre_bundle_create(name)
      yaml_path = Path.join(@scratch_dir, "#{name}.yaml")
      run("cogctl bundle install --templates #{@template_dir} #{yaml_path}")
    end)

    pre_bundle_create("bundle4")
    run("cogctl bundle install --enable --relay-groups=myrelays #{Path.join(@scratch_dir, "bundle4.yaml")}")

    assert run("cogctl bundle info bundle4") =~ ~r"""
    Bundle ID:           .*
    Version ID:          .*
    Name:                bundle4
    Installed Versions:  0.0.1
    Status:              Enabled
    Version:             0.0.1
    Commands:            bar
    Relay Groups:        myrelays
    """

    assert run("cogctl relay-groups assign myrelays --bundles=#{Enum.join(bundle_names, ",")}") =~ ~r"""
    Assigned "bundle1", "bundle2", "bundle3" to relay group "myrelays"
    """

    assert run("cogctl relay-groups info myrelays") =~ ~r"""
    Name           myrelays
    ID             .*
    Creation Time  .*

    Relays
    NAME  ID

    Bundles
    NAME     ID
    bundle1  .*
    bundle2  .*
    bundle3  .*
    bundle4  .*
    """

    # Cleanup the bundle bits when we are finished
    Enum.each(bundle_names, &run("cogctl bundle disable #{&1}"))
    Enum.each(bundle_names, &run("cogctl bundle uninstall --all #{&1}"))
    run("cogctl bundle uninstall bundle4 --all")
    cleanup

    assert run("cogctl relay-groups delete myrelays") =~ ~r"""
    Deleted relay group `myrelays`
    """
    assert run("cogctl relay-groups create testgroup --members relay1,test-relay,relay3") =~ ~r"""
    ID    .*
    Name  testgroup
    """

    run("cogctl relays delete test-relay my-test")
    run("cogctl relay-groups delete testgroup")
  end

  test "cogctl triggers" do

    # Set up some users for the triggers
    run("""
    cogctl users create
      --first-name=Trigger
      --last-name=User1
      --email=trigger1@operable.io
      --username=trigger_user1
      --password=password
    """)

    run("""
    cogctl users create
      --first-name=Trigger
      --last-name=User2
      --email=trigger2@operable.io
      --username=trigger_user2
      --password=password
    """)

    assert run("cogctl triggers") =~ ~r"""
    Name  ID  Enabled  Pipeline
    """

    assert run("cogctl triggers create --name=echo_stuff --pipeline=echo_stuff --as-user=trigger_user1 --timeout-sec=60 --description=echo_some_stuff") =~ ~r"""
    ID              .*
    Name            echo_stuff
    Pipeline        echo_stuff
    Enabled         true
    As User         trigger_user1
    Timeout \(sec\)   60
    Description     echo_some_stuff
    Invocation URL  .*
    """

    assert run("cogctl triggers") =~ ~r"""
    Name        ID                                    Enabled  Pipeline
    echo_stuff  [a-f0-9\-]{36}  true     echo_stuff
    """

    assert run("cogctl triggers info echo_stuff") =~ ~r"""
    ID              .*
    Name            echo_stuff
    Pipeline        echo_stuff
    Enabled         true
    As User         trigger_user1
    Timeout \(sec\)   60
    Description     echo_some_stuff
    Invocation URL  .*
    """

    assert run("cogctl triggers disable echo_stuff") =~ ~r"""
    Disabled trigger echo_stuff
    """

    assert run("cogctl triggers enable echo_stuff") =~ ~r"""
    Enabled trigger echo_stuff
    """
    assert run("cogctl triggers update echo_stuff --timeout-sec=120 --as-user=trigger_user2 --pipeline=another_command") =~ ~r"""
    Updated echo_stuff

    ID              .*
    Name            echo_stuff
    Pipeline        another_command
    Enabled         true
    As User         trigger_user2
    Timeout \(sec\)   120
    Description     echo_some_stuff
    Invocation URL  .*
    """

    assert run("cogctl triggers delete echo_stuff") =~ ~r"""
    Deleted echo_stuff
    """

    run("cogctl users delete trigger_user1")
    run("cogctl users delete trigger_user2")

  end

end
