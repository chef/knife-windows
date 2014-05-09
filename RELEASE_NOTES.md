<!---
This file is reset every time a new release is done. The contents of this file are for the currently unreleased version.

Example Note:

## Example Heading
Details about the thing that changed that needs to get included in the Release Notes in markdown.
-->
# knife-windows 0.6.0 release notes:
This release of knife-windows addresses issues with reliability of winrm
readiness detection during Windows bootstrap, exit codes in command execution
scenarios, and gem dependencies.

Special thanks to **Okezie Eze** for the helpful bug report in KNIFE-386.
Issues with `knife-windows` should be reported in the ticketing system at
https://tickets.opscode.com/browse/KNIFE. Learn more about how you can
contribute features and bug fixes to `knife-windows` at https://wiki.opscode.com/display/chef/How+to+Contribute.

## Features added in knife-windows 0.6.0

### `--auth-timeout` option for bootstrap
The `knife windows bootstrap` command has an `--auth-timeout` option that
takes as an argument a number of minutes that specifies the time period during
which to retry authentication attempts to WinRM when boostrapping a remote
node via WinRM. By default, the value is 25 minutes. This retry behavior during bootstrap addresses issues that arise on
some cloud providers where the authentication system is not ready until
some time after WinRM is ready.

## knife-windows on RubyGems and Github
https://rubygems.org/gems/knife-windows
https://github.com/opscode/knife-windows

## Issues fixed in knife-windows 0.6.0
* [KNIFE-386](https://tickets.opscode.com/browse/KNIFE-386) Wait for a valid command response before bootstrapping over WinRM
* [KNIFE-394](https://tickets.opscode.com/browse/KNIFE-394) Update em-winrm dependency
* [KNIFE-450](https://tickets.opscode.com/browse/KNIFE-450) Set knife winrm command exit status on exception and command failure

## knife-windows breaking changes:

None.
