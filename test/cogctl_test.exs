defmodule CogctlTest do
  use Support.CliCase

  doctest Cogctl

  test "cogctl" do
    assert run("cogctl") == """
    Usage: cogctl [bootstrap | profiles | bundles | bundles info | bundle delete | users | users info | users create | users update | users delete | groups | groups info | groups create | groups update | groups delete | groups add | groups remove | roles | roles create | roles update | roles delete | roles grant | roles revoke | permissions | permissions create | permissions delete | permissions grant | permissions revoke]

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
      --first-name=Kevin
      --last-name=Smith
      --email=kevin@operable.io
      --username=kevsmith
      --password=password
    """)

    assert output =~ ~r"""
    Created kevsmith

    ID          .*
    Username    kevsmith                            
    First Name  Kevin                               
    Last Name   Smith                               
    Email       kevin@operable.io                   
    """

    assert run("""
    cogctl users update kevsmith
      --last-name=Smitherino
    """) =~ ~r"""
    Updated kevsmith

    ID          .*
    Username    kevsmith                            
    First Name  Kevin                               
    Last Name   Smitherino                          
    Email       kevin@operable.io                   
    """

    assert run("cogctl users delete kevsmith") =~ ~r"""
    Deleted kevsmith
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
    operable:help                .*
    operable:manage_commands     .*
    operable:manage_groups       .*
    operable:manage_roles        .*
    operable:manage_users        .*
    operable:manage_permissions  .*
    """

    assert run("cogctl permissions create site:echo") =~ ~r"""
    Created site:echo
    """

    assert run("cogctl permissions grant site:echo --user=admin") =~ ~r"""
    Granted site:echo to admin
    """

    assert run("cogctl permissions revoke site:echo --user=admin") =~ ~r"""
    Revoked site:echo from admin
    """

    assert run("cogctl permissions delete site:echo") =~ ~r"""
    Deleted site:echo
    """
  end
end
