defmodule CogctlTest do
  use Support.CliCase

  doctest Cogctl

  test "cogctl" do
    assert run("cogctl") == """
    Usage: cogctl [bootstrap | profiles | bundles | bundles info | bundle delete | users | users info | users create | users update | users delete | groups | groups info | groups create | groups update | groups delete | groups add | groups remove | roles | roles create | roles update | roles delete | roles grant | roles revoke | rules | rules create | rules delete | permissions | permissions create | permissions delete | permissions grant | permissions revoke]

           cogctl <action> --help will display action specific help information.
    """
  end

  test "cogctl bundles" do
    assert run("cogctl bundles") =~ ~r"""
    NAME      INSTALLED           
    operable  .*
    """

    assert run("cogctl bundles info operable") =~ ~r"""
    ID         .*
    Name       operable                            
    Installed  .*                
    
    Commands
    NAME         ID                                  
    echo         .*
    filter       .*
    greet        .*
    group        .*
    help         .*
    max          .*
    min          .*
    permissions  .*
    role         .*
    rules        .*
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
    NAME                ID                                  
    help                .*
    manage_commands     .*
    manage_groups       .*
    manage_roles        .*
    manage_users        .*
    manage_permissions  .*
    """

    assert run("cogctl permissions create --name=test_echo") =~ ~r"""
    Created test_echo
    """

    assert run("cogctl permissions grant site:test_echo --user=admin") =~ ~r"""
    Granted site:test_echo to admin
    """

    assert run("cogctl permissions revoke site:test_echo --user=admin") =~ ~r"""
    Revoked site:test_echo from admin
    """

    assert run("cogctl permissions delete test_echo") =~ ~r"""
    Deleted test_echo
    """
  end

  test "cogctl rules" do
    assert run("cogctl rules operable:test") =~ ~r"""
    Error: {:error, %{"errors" => "No rules for command found"}}
    """

    # Set up the permission
    run("cogctl permission create --name test")

    assert run("cogctl rules create --rule_text='when command is operable:echo must have site:test'") =~ ~r"""
    Added the rule 'when command is operable:echo must have site:test'
    
    ID                                    Rule                                             
    .*  when command is operable:echo must have site:test
    """

    expected = ~r"""
    ID                                    COMMAND        RULE TEXT                                        
    (?<id>.*)  operable:echo  when command is operable:echo must have site:test
    """
    m = Regex.named_captures(expected, run("cogctl rules operable:echo"))

    assert run("cogctl rules delete -r #{m["id"]}") =~ ~r"""
    Deleted .*
    """

    # Clean up the permission after we are done
    run("cogctl permission delete test")
  end
end
