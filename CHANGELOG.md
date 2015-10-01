# knife-windows Change Log

## Release 1.0.0

* [knife-windows #293](https://github.com/chef/knife-windows/issues/293) bootstrap fails on windows 2012 when cmd extensions are disabled in the registry
* [knife-windows #281](https://github.com/chef/knife-windows/pull/281) Prevent unencrypted negotiate auth, automatically prefix local usernames with '.' for negotiate
* [knife-windows #275](https://github.com/chef/knife-windows/pull/275) Added bootstrap\_install\_command option in parity with knife bootstrap
* [knife-windows #240](https://github.com/chef/knife-windows/pull/240) Change kerberos keytab short option to -T to resolve conflict
* [knife-windows #232](https://github.com/chef/knife-windows/pull/232) Adding --hint option to bootstrap
* [knife-windows #227](https://github.com/chef/knife-windows/issues/227) Exception: NoMethodError: undefined method 'gsub' for false:FalseClass
* [knife-windows #222](https://github.com/chef/knife-windows/issues/222) Validatorless bootstrap support
* [knife-windows #202](https://github.com/chef/knife-windows/issues/202) knife windows bootstrap should support enabling the service
* [knife-windows #213](https://github.com/chef/knife-windows/pull/213) Search possibilities of HOME for bootstrap templates
* [knife-windows #206](https://github.com/chef/knife-windows/pull/206) Add a flag msi_url that allows one to fetch the Chef client msi from a non-chef.io path
* [knife-windows #192](https://github.com/chef/knife-windows/issues/192) deprecate knife bootstrap --distro
* [knife-windows #159](https://github.com/opscode/knife-windows/issues/159) `winrm_port` option should default to 5986 if `winrm_transport` option is `ssl`
* [knife-windows #149](https://github.com/chef/knife-windows/pull/149) Adding knife wsman test to validate WSMAN/WinRM availability
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
* [knife-windows #252](https://github.com/chef/knife-windows/pull/252) Fail early on ECONNREFUSED, Closes #244.
* [knife-windows #260](https://github.com/chef/knife-windows/pull/260) Fail quickly on invalid option combinations, Closes #259

## Release: 0.8.5
* [knife-windows #228](https://github.com/chef/knife-windows/pull/228) make winrm-s dep more strict on knife-windows 0.8.x

## Release: 0.8.4
* [knife-windows #133](https://github.com/opscode/knife-windows/issues/133) Bootstrap failure -- unable to validate SSL chef server endpoints

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

