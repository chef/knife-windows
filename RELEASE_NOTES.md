<!---
This file is reset every time a new release is done. The contents of this file are for the currently unreleased version.

Example Note:

## Example Heading
Details about the thing that changed that needs to get included in the Release Notes in markdown.
-->
# knife-windows 1.1.0 release notes:
This release of knife-windows includes an important fix for an
incompatibility issue with Chef Client 12.5 during bootstrap. If you
are running knife-windows 1.0.0, please upgrade to this version. See
the following issue for details: https://github.com/chef/knife-windows/pull/302

You can install this version using the `gem` command:

    gem install knife-windows

## Reporting issues and contributing
`knife-windows` issues like those addressed in this release should be reported in the ticketing system at https://github.com/chef/knife-windows/issues. You can learn more about how to contribute features and bug fixes to `knife-windows` in the [Chef Contributions document](http://docs.chef.io/community_contributions.html).

## New features -- proxy support for WinRM
The `winrm` and `bootstrap windows winrm` subcommands now honor the
proxy server configured via the `http_proxy` setting in `knife.rb` for
WinRM traffic.

## Issues fixed in knife-windows 1.1.0
See the [knife-windows 1.1.0 CHANGELOG](https://github.com/chef/knife-windows/blob/1.1.0/CHANGELOG.md)
for the list of issues fixed in this release.

## knife-windows on RubyGems and Github
https://rubygems.org/gems/knife-windows
https://github.com/chef/knife-windows

