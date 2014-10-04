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

A thank you goes to contributor **Josh Mahowald** for contributing a fix to return nonzero exit codes.

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
* [knife-windows #98](https://github.com/opscode/knife-windows/issues/96) Get winrm command exit code if it is not expected
* [knife-windows #96](https://github.com/opscode/knife-windows/issues/96) Fix break from OS patch KB2918614
* Update winrm-s dependency along with em-winrm and winrm dependencies
* Return failure codes from knife winrm even when `returns` is not set
* Support Windows negotiate authentication protocol when running knife on Windows

