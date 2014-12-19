<!---
This file is reset every time a new release is done. The contents of this file are for the currently unreleased version.

Example Note:

## Example Heading
Details about the thing that changed that needs to get included in the Release Notes in markdown.
-->
# knife-windows 0.8.3 release notes
This release of knife-windows addresses a bug exposed by the Chef Client 12.0
release where Windows nodes are bootstrapped with Chef Client 12 even though
the Chef Client version of knife is 11, which is inconsistent with the
bootstrap behavior of non-Windows systems with knife (such systems are correctly
bootstrapped with Chef Client 11):

[knife-windows #131](https://github.com/opscode/knife-windows/issues/131) Windows should be bootstrapped using latest Chef Client version compatible with knife's version just like non-Windows systems. 

You can install the fix for this issue by upgrading to this new version using
the `gem` command:

    gem install knife-windows --pre

Our thanks go to **David Crowder** for reporting [knife-windows #131](https://github.com/opscode/knife-windows/issues/131).

## Reporting issues and contributing

`knife-windows` issues like the one addressed in this release should be
reported in the ticketing system at https://github.com/opscode/knife-windows/issues. You can learn more about how to contribute features and bug fixes to `knife-windows` in the [Chef Contributions document](http://docs.opscode.com/community_contributions.html).

## Features added in knife-windows 0.8.3
None.

## Issues fixed in knife-windows 0.8.3
[knife-windows #131](https://github.com/opscode/knife-windows/issues/131) Windows should be bootstrapped using latest Chef Client version compatible with knife's version just like non-Windows systems. 

## knife-windows on RubyGems and Github
https://rubygems.org/gems/knife-windows
https://github.com/opscode/knife-windows

