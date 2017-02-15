Feature: Add, delete, and view triggers

  Scenario: executing cogctl trigger --help returns basic help
    When I successfully run `cogctl trigger --help`
    Then the output should contain:
    """
    Usage: cogctl trigger [OPTIONS] COMMAND [ARGS]...

      Create, edit, delete, and view Cog triggers.

      If invoked without a subcommand, lists all triggers.

    Options:
      --help  Show this message and exit.

    Commands:
      create  Create a new trigger
      delete  Delete a trigger
      info    Display trigger details
      update  Update trigger configuration
    """

  # Scenario: executing cogctl trigger create fails when user is missing
  #   When I run `cogctl trigger create blah help --as-user ned`
  #   Then the output should match /Error: User \"ned\" was not found/

  # Scenario: executing cogctl trigger create creates a trigger
  #   When I successfully run `cogctl trigger create blah help`
  #   Then the output should contain:
  #   """
  #   Name      blah
  #   Pipeline  help
  #   Enabled   False
  #   """

  # Scenario: executing cogctl trigger update updates a trigger
  #   When I successfully run `cogctl trigger update blah --enable`
  #   Then the output should match /Enabled         True/

  # Scenario: executing cogctl trigger delete works
  #   When I successfully run `cogctl trigger delete blah --force         `
  #   Then the output should match /Trigger \"blah\" deleted/
