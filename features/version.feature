Feature: Provide version information

  Scenario: Displaying basic version information

    The version string should contain the main version, as well as a
    short Git SHA of the commit from which the binary was built.

    When I successfully run `cogctl version`
    Then the output should match /^cogctl 1.0.0-beta \(build: [a-f0-9]{7}\)/
