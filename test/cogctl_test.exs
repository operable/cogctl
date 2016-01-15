defmodule CogctlTest do
  use Support.CliCase

  doctest Cogctl

  test "cogctl" do
    assert run("cogctl") == """
    Usage: cogctl [bootstrap | profiles | bundles | bundles info | bundle delete | users | users info | users create | users update | users delete | groups | groups create | groups update | groups delete | groups add | roles | roles create | roles update | roles delete]

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
    NAME           ID                                  
    builds         .*
    echo           .*
    giphy          .*
    greet          .*
    group          .*
    help           .*
    math           .*
    max            .*
    min            .*
    permissions    .*
    role           .*
    rules          .*
    stack          .*
    stackoverflow  .*
    sum            .*
    table          .*
    thorn          .*
    wc             .*
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

    assert run("cogctl groups") =~ ~r"""
    NAME   ID                                  
    admin  .*
    """

    assert run("cogctl groups update admin --name=ops") =~ ~r"""
    Updated admin

    ID    .*
    Name  ops                                 
    """

    assert run("cogctl groups add ops --user=admin") =~ ~r"""
    Added admin to ops
    """

    assert run("cogctl groups delete ops") =~ ~r"""
    Deleted ops
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

    assert run("cogctl roles delete support") =~ ~r"""
    Deleted support
    """
  end
end
