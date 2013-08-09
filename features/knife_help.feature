Feature: Ensure that the help works as designed
  In order to test the help via CLI
  As an Operator
  I want to run the CLI with different arguments

Scenario: Running the windows sub-command shows available commands
  When I run `knife windows`
  And the output should contain "Available windows subcommands: (for details, knife SUB-COMMAND --help)\n\n** WINDOWS COMMANDS **\nknife bootstrap windows winrm FQDN (options)\nknife bootstrap windows ssh FQDN (options)\nknife winrm QUERY COMMAND (options)"

Scenario: Running the windows sub-command shows available commands
  When I run `knife windows --help`
  And the output should contain "Available windows subcommands: (for details, knife SUB-COMMAND --help)\n\n** WINDOWS COMMANDS **\nknife bootstrap windows winrm FQDN (options)\nknife bootstrap windows ssh FQDN (options)\nknife winrm QUERY COMMAND (options)"

Scenario: Running the windows sub-command shows available commands
  When I run `knife windows help`
  And the output should contain "Available windows subcommands: (for details, knife SUB-COMMAND --help)\n\n** WINDOWS COMMANDS **\nknife bootstrap windows winrm FQDN (options)\nknife bootstrap windows ssh FQDN (options)\nknife winrm QUERY COMMAND (options)"

Scenario: Running the knife command shows available windows command"
  When I run `knife`
  And the output should contain "** WINDOWS COMMANDS **\nknife bootstrap windows winrm FQDN (options)\nknife bootstrap windows ssh FQDN (options)\nknife winrm QUERY COMMAND (options)"
