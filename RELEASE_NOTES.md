<!---
This file is reset every time a new release is done. The contents of this file are for the currently unreleased version.

Example Note:

## Example Heading
Details about the thing that changed that needs to get included in the Release Notes in markdown.
-->
# knife-windows 0.8.0 release notes:
This release of knife-windows enables the Windows negotiate protocol to be
used with the `winrm` and `bootstrap windows winrm` subcommands and also
contains bug fixes and dependency updates.

A thank you goes to contributor **Josh Mahowald** for contributing a fix for
[KNIFE-450](https://tickets.opscode.com/browse/KNIFE-450).

Issues with `knife-windows` should be reported in the ticketing system at
https://github.com/opscode/knife-windows/issues. Learn more about how you can
contribute features and bug fixes to `knife-windows` in the [Chef Contributions document](http://docs.opscode.com/community_contributions.html).

## Features added in knife-windows 0.8.0

### NTLM / Negotiate authentication for `winrm` and `bootstrap`
If `knife` is being used on a Windows workstation, it is no longer necessary
to use Kerberos or to use certificate authentication to authenticate securely
with a remote node in bootstrap or command execution scenarios. The `knife winrm` and `knife
windows bootstrap` commands now support the use of NTLM to authenticate to remote
nodes with the default WinRM listener configuration set by the operating
system's `winrm quickconfig` command.

When specifying the user name on the command-line or configuration, the format `domain\username` must be used for
the negotiate protocol to be invoked. If the account is local to the node,
'`.`' may be used for the domain. See the README.md for further detail.

## knife-windows on RubyGems and Github
https://rubygems.org/gems/knife-windows
https://github.com/opscode/knife-windows

## Issues fixed in knife-windows 0.8.0
* [KNIFE-386](https://tickets.opscode.com/browse/KNIFE-386) Wait for a valid command response before bootstrapping over WinRM
* [KNIFE-394](https://tickets.opscode.com/browse/KNIFE-394) Update em-winrm dependency
* [KNIFE-450](https://tickets.opscode.com/browse/KNIFE-450) Set knife winrm command exit status on exception and command failure

## knife-windows breaking changes

### Error status being returned from `winrm` and `bootstrap windows winrm` remote commands

Previously, `knife winrm` would always return an exit status of 0 if it was able to
execute a command on the remote node, regardless whether the command that it
invoked on the remote node returned a status of 0. It now returns a non-zero
exit code if the command's exit code was non-zero. This may cause failures in
scripts that use the `knife winrm` or `knife bootstrap windows winrm` commands
and check to see if the exit status of the command is successful (0). Such
scripts should be altered to ignore the exit status if the failure is truly non-fatal.
