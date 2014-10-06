# knife-windows Change Log

## Unreleased changes
None.

## Latest release: 0.8.0
* [knife-windows #98](https://github.com/opscode/knife-windows/issues/96) Get winrm command exit code if it is not expected
* [knife-windows #96](https://github.com/opscode/knife-windows/issues/96) Fix break from OS patch KB2918614
* Remove the 'instance data' method of creating EC2 servers
* Update winrm-s dependency along with em-winrm and winrm dependencies
* Return failure codes from knife winrm even when `returns` is not set
* Support Windows negotiate authentication protocol when running knife on Windows

## Release: 0.6.0 (05/08/2014)

* [KNIFE-386](https://tickets.opscode.com/browse/KNIFE-386) Wait for a valid command response before bootstrapping over WinRM
* [KNIFE-394](https://tickets.opscode.com/browse/KNIFE-394) Update em-winrm dependency
* [KNIFE-450](https://tickets.opscode.com/browse/KNIFE-450) Set knife winrm command exit status on exception and command failure

**See source control commit history for earlier changes.**

## Selected release notes
These are release notes from very early releases of the plugin. For recent
releases (2014 and later), see the RELEASE_NOTES.md file of each tagged release branch.

Release Notes - Knife Windows Plugin - Version 0.5.6

** New Feature
    * new default bootstrap template that installs Chef using official chef-client MSI installer

Release Notes - Knife Windows Plugin - Version 0.5.4

** Bug
    * [KNIFE\_WINDOWS-7] - Exception: NoMethodError: undefined method `env_namespace' for Savon:Module
    * [KNIFE\_WINDOWS-8] - winrm based bootstrap fails with 'Bad HTTP response returned from server (500)'


** New Feature
    * [KNIFE\_WINDOWS-6] - default bootstrap template should support encrypted\_data\_bag\_secret

