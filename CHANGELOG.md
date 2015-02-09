# knife-windows Change Log

## Unreleased changes

* [knife-windows #159](https://github.com/opscode/knife-windows/issues/159) `winrm_port` option should default to 5986 if `winrm_transport` option is `ssl`
* [knife-windows #139](https://github.com/opscode/knife-windows/issues/139) Force dev dependency on Chef 11 for test scenarios to avoid Ohai 8 conflict on Ruby 1.9.x
* [knife-windows #126](https://github.com/opscode/knife-windows/pull/126) Allow disabling of SSL peer verification in knife-windows for testing
* [knife-windows #154](https://github.com/opscode/knife-windows/issues/154) Unreleased regression in master: NameError: undefined local variable or method `path_separator
* [knife-windows #143](https://github.com/opscode/knife-windows/issues/143) Unreleased regression in master: WinRM::WinRMHTTPTransportError: Bad HTTP response returned from server (503) in the middle of bootstrap
* [knife-windows #133](https://github.com/opscode/knife-windows/issues/133) Bootstrap failure -- unable to validate SSL chef server endpoints
* [knife-windows #132](https://github.com/opscode/knife-windows/issues/132) New subcommands for WinRM: windows listener create, cert generate, and cert install
* [knife-windows #129](https://github.com/opscode/knife-windows/issues/129) New --winrm-authentication-protocol option for explicit control of authentication
* [knife-windows #125](https://github.com/opscode/knife-windows/issues/125) knife-windows should use PowerShell first before cscript to download the  Chef Client msi
* [knife-windows #92](https://github.com/opscode/knife-windows/issues/92) EventMachine issue: knife bootstrap windows winrm error
* [knife-windows #94](https://github.com/opscode/knife-windows/issues/94) Remove Eventmachine dependency

## Release: 0.8.3
* [knife-windows #131](https://github.com/opscode/knife-windows/issues/108) Issue #131: Windows should be bootstrapped using latest Chef Client version compatible with knife's version just like non-Windows systems
* [knife-windows #139](https://github.com/opscode/knife-windows/issues/139) Force dev dependency on Chef 11 for test scenarios to avoid Ohai 8 conflict on Ruby 1.9.x

## Release: 0.8.2
* [knife-windows #108](https://github.com/opscode/knife-windows/issues/108) Error: Unencrypted communication not supported if remote server does not require encryption

## Release: 0.8.0
* [knife-windows #98](https://github.com/opscode/knife-windows/issues/98) Get winrm command exit code if it is not expected
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

