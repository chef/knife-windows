<!---
This file is reset every time a new release is done. The contents of this file are for the currently unreleased version.

Example Note:

## Example Heading
Details about the thing that changed that needs to get included in the Release Notes in markdown.
-->
# knife-windows 0.8.2.rc.0 release notes:
This release of knife-windows addresses a regression in knife-windows 0.8.0
from previous releases where `knife winrm` and `knife bootstrap windows`
commands fail due to inability to authenticate:
[knife-windows #108](https://github.com/opscode/knife-windows/issues/108). 

You can install the fix for this issue by upgrading to this new version using
the `gem` command:

    gem install knife-windows --pre

A thank you goes to **Richard Lavey** for reporting [knife-windows #108](https://github.com/opscode/knife-windows/issues/108).

## Impact of [knife-windows #108](https://github.com/opscode/knife-windows/issues/108)

[knife-windows #108](https://github.com/opscode/knife-windows/issues/108) will affect a given user if all of the following are true:

* You are running `knife-windows` subcommands on a Windows workstation
* The remote node you're interacting with via `knife-windows` has a WinRM
  configuration with the `WSMan:\localhost\Service\AllowUnencrypted` (in
  PowerShell's WinRM settings drive provider)
  
In this situation, you will receive an authentication error message from
the `knife winrm` or `knife bootstrap windows` command such as
`Error: Unencrypted communication not supported`. To resolve this error,
simply install this version of the gem as described earlier.

If you are running the `knife` commands from a non-Windows operating system,
[knife-windows #108](https://github.com/opscode/knife-windows/issues/108) does
not affect you, so you don't need to upgrade just for this issue.

## Reporting issues and contributing

`knife-windows` issues like the one addressed in this release should be
reported in the ticketing system at https://github.com/opscode/knife-windows/issues. You can learn more about how to contribute features and bug fixes to `knife-windows` in the [Chef Contributions document](http://docs.opscode.com/community_contributions.html).

## Features added in knife-windows 0.8.2
None.

## Issues fixed in knife-windows 0.8.2
[knife-windows #108](https://github.com/opscode/knife-windows/issues/108) Error: Unencrypted communication not supported if remote server does not require encryption

The fix in this release will cause a behavior change from the 0.8.0 release:

* As described in the [documentation changes](https://github.com/opscode/knife-windows/blob/0.8.0/DOC_CHANGES.md) for the 0.8.0 release of the `knife-windows`, the negotiate authentication
  protocol will only be used in this 0.8.2 release if a domain is specified (you can specify '.' as
  the domain if you want to use the local workstation as the domain). Due to a
  defect in the 0.8.0 release, the negotiate protocol was being used even when
  the domain was not specified.

## knife-windows on RubyGems and Github
https://rubygems.org/gems/knife-windows
https://github.com/opscode/knife-windows

