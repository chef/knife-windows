# knife-windows Change Log

Note: this log contains only changes from knife-windows release 0.6.0 and later
-- it does not contain the changes from prior releases. To view change history
prior to release 0.6.0, please visit the [source repository](https://github.com/chef/knife-windows/commits).

<!-- latest_release 5.0.0 -->
## [v5.0.0](https://github.com/chef/knife-windows/tree/v5.0.0) (2021-08-25)

#### Merged Pull Requests
- Require Ruby 2.7+ and the knife gem [#517](https://github.com/chef/knife-windows/pull/517) ([tas50](https://github.com/tas50))
<!-- latest_release -->

<!-- release_rollup since=4.0.7 -->
### Changes not yet released to rubygems.org

#### Merged Pull Requests
- Require Ruby 2.7+ and the knife gem [#517](https://github.com/chef/knife-windows/pull/517) ([tas50](https://github.com/tas50)) <!-- 5.0.0 -->
- Fixed knife winrm fails with echo as undefined [#514](https://github.com/chef/knife-windows/pull/514) ([sanga1794](https://github.com/sanga1794)) <!-- 4.0.10 -->
- Upgrade to GitHub-native Dependabot [#511](https://github.com/chef/knife-windows/pull/511) ([dependabot-preview[bot]](https://github.com/dependabot-preview[bot])) <!-- 4.0.9 -->
- Support external testing [#512](https://github.com/chef/knife-windows/pull/512) ([lamont-granquist](https://github.com/lamont-granquist)) <!-- 4.0.8 -->
<!-- release_rollup -->

<!-- latest_stable_release -->
## [v4.0.7](https://github.com/chef/knife-windows/tree/v4.0.7) (2021-03-25)

#### Merged Pull Requests
- Fix test for ruby-3.0 [#510](https://github.com/chef/knife-windows/pull/510) ([lamont-granquist](https://github.com/lamont-granquist))
<!-- latest_stable_release -->

## [v4.0.6](https://github.com/chef/knife-windows/tree/v4.0.6) (2020-09-09)

#### Merged Pull Requests
- autoload winrm [#509](https://github.com/chef/knife-windows/pull/509) ([mwrock](https://github.com/mwrock))

## [v4.0.5](https://github.com/chef/knife-windows/tree/v4.0.5) (2020-08-21)

#### Merged Pull Requests
- Fix chefstyle violations. [#508](https://github.com/chef/knife-windows/pull/508) ([phiggins](https://github.com/phiggins))
- Remove old spec files for knife bootstrap [#507](https://github.com/chef/knife-windows/pull/507) ([tas50](https://github.com/tas50))
- Optimize our requires [#506](https://github.com/chef/knife-windows/pull/506) ([tas50](https://github.com/tas50))

## [v4.0.2](https://github.com/chef/knife-windows/tree/v4.0.2) (2020-05-30)

#### Merged Pull Requests
- Fix an include of the removed library [#504](https://github.com/chef/knife-windows/pull/504) ([tas50](https://github.com/tas50))

## [v4.0.1](https://github.com/chef/knife-windows/tree/v4.0.1) (2020-05-30)

#### Merged Pull Requests
- Don&#39;t try to require the removed lib [#503](https://github.com/chef/knife-windows/pull/503) ([tas50](https://github.com/tas50))

## [v4.0.0](https://github.com/chef/knife-windows/tree/v4.0.0) (2020-05-29)

#### Merged Pull Requests
- Chef 16 fixes for knife-windows [#502](https://github.com/chef/knife-windows/pull/502) ([lamont-granquist](https://github.com/lamont-granquist))

## [v3.0.17](https://github.com/chef/knife-windows/tree/v3.0.17) (2020-05-17)

#### Merged Pull Requests
- Fixed Exception: NameError: uninitialized constant Chef::Knife::Winrm… [#500](https://github.com/chef/knife-windows/pull/500) ([sanga1794](https://github.com/sanga1794))

## [v3.0.16](https://github.com/chef/knife-windows/tree/v3.0.16) (2020-02-11)

#### Merged Pull Requests
- Further optimize load times for the knife-windows plugins [#497](https://github.com/chef/knife-windows/pull/497) ([tas50](https://github.com/tas50))

## [v3.0.15](https://github.com/chef/knife-windows/tree/v3.0.15) (2020-02-11)

#### Merged Pull Requests
- Lazy load winrm_session for speedup [#496](https://github.com/chef/knife-windows/pull/496) ([tas50](https://github.com/tas50))

## [v3.0.14](https://github.com/chef/knife-windows/tree/v3.0.14) (2020-02-07)

#### Merged Pull Requests
- Mark bootstrap deprecated and remove extra windows help [#495](https://github.com/chef/knife-windows/pull/495) ([tas50](https://github.com/tas50))

## [v3.0.13](https://github.com/chef/knife-windows/tree/v3.0.13) (2020-02-07)

#### Merged Pull Requests
- Fix failures loading the banner [#494](https://github.com/chef/knife-windows/pull/494) ([tas50](https://github.com/tas50))

## [v3.0.12](https://github.com/chef/knife-windows/tree/v3.0.12) (2020-02-07)

#### Merged Pull Requests
- Require libraries only where we need them [#493](https://github.com/chef/knife-windows/pull/493) ([tas50](https://github.com/tas50))

## [v3.0.11](https://github.com/chef/knife-windows/tree/v3.0.11) (2020-02-04)

#### Merged Pull Requests
- Fix multiple session issue of concurrency flag [#484](https://github.com/chef/knife-windows/pull/484) ([NAshwini](https://github.com/NAshwini))

## [v3.0.10](https://github.com/chef/knife-windows/tree/v3.0.10) (2020-01-30)

#### Merged Pull Requests
- Test on the final Ruby 2.7 container + cleanup test files [#489](https://github.com/chef/knife-windows/pull/489) ([tas50](https://github.com/tas50))
- Run tests on Windows [#490](https://github.com/chef/knife-windows/pull/490) ([tas50](https://github.com/tas50))
- Apply Chefstyle and enforce style [#491](https://github.com/chef/knife-windows/pull/491) ([tas50](https://github.com/tas50))
- Remove extra test deps we don&#39;t need [#492](https://github.com/chef/knife-windows/pull/492) ([tas50](https://github.com/tas50))

## [v3.0.6](https://github.com/chef/knife-windows/tree/v3.0.6) (2019-12-21)

#### Merged Pull Requests
- Update README.md as per Chef OSS Best Practices [#483](https://github.com/chef/knife-windows/pull/483) ([vsingh-msys](https://github.com/vsingh-msys))
- Add testing in Buildkite [#488](https://github.com/chef/knife-windows/pull/488) ([tas50](https://github.com/tas50))
- Substitute require for require_relative [#487](https://github.com/chef/knife-windows/pull/487) ([tas50](https://github.com/tas50))

## [v3.0.3](https://github.com/chef/knife-windows/tree/v3.0.3) (2019-05-17)

#### Merged Pull Requests
- Detect if chef-client is already present [#464](https://github.com/chef/knife-windows/pull/464) ([vijaymmali1990](https://github.com/vijaymmali1990))
- Require Ruby 2.2+ and slim down the files we ship [#465](https://github.com/chef/knife-windows/pull/465) ([tas50](https://github.com/tas50))
- Using chef/chef path_helper and removed the knife-windows path_helper [#471](https://github.com/chef/knife-windows/pull/471) ([Vasu1105](https://github.com/Vasu1105))
- Removed deprecated host_key_verification, distro and template_file options [#470](https://github.com/chef/knife-windows/pull/470) ([dheerajd-msys](https://github.com/dheerajd-msys))
- Require Ruby 2.4 or later [#473](https://github.com/chef/knife-windows/pull/473) ([tas50](https://github.com/tas50))
- fix log_level incosistency [#476](https://github.com/chef/knife-windows/pull/476) ([dheerajd-msys](https://github.com/dheerajd-msys))
- Removed support &amp; specs for chefv12 and lower [#475](https://github.com/chef/knife-windows/pull/475) ([dheerajd-msys](https://github.com/dheerajd-msys))
- Prep branch for knife-windows v3 [#477](https://github.com/chef/knife-windows/pull/477) ([btm](https://github.com/btm))
- [WIP] Remove knife bootstrap windows [#478](https://github.com/chef/knife-windows/pull/478) ([vsingh-msys](https://github.com/vsingh-msys))
- Load bootstrap dependency [#480](https://github.com/chef/knife-windows/pull/480) ([vsingh-msys](https://github.com/vsingh-msys))
- Require Chef Infra 15 [#481](https://github.com/chef/knife-windows/pull/481) ([btm](https://github.com/btm))

## [v1.9.6](https://github.com/chef/knife-windows/tree/v1.9.6) (2018-10-23)

#### Merged Pull Requests
- [MSYS-850] enable expeditor [#458](https://github.com/chef/knife-windows/pull/458) ([dheerajd-msys](https://github.com/dheerajd-msys))
- [MSYS-841]fix bootstrap template short name [#457](https://github.com/chef/knife-windows/pull/457) ([dheerajd-msys](https://github.com/dheerajd-msys))
- MSYS-831 : Fixed windows detection code for windows 2016, windows 2012r2 [#455](https://github.com/chef/knife-windows/pull/455) ([piyushawasthi](https://github.com/piyushawasthi))
- Adds client_d support to knife-windows [#461](https://github.com/chef/knife-windows/pull/461) ([btm](https://github.com/btm))
- Slim down the size of the install and the gem [#462](https://github.com/chef/knife-windows/pull/462) ([tas50](https://github.com/tas50))



## Release 1.9.1 (2018-03-07)

* [knife-windows #444](https://github.com/chef/knife-windows/pull/444) Fixes issue when bootstrapping windows systems failing with the message: The input line is too long.

## Release 1.9.0

* [knife-windows #416](https://github.com/chef/knife-windows/pull/416) Add concurrency support via the `--concurrency` flag

## Release 1.8.0

* [knife-windows #407](https://github.com/chef/knife-windows/pull/407) Added value for config_log_level and config_log_location

## Release 1.7.1

* [knife-windows #409](https://github.com/chef/knife-windows/pull/409) Fix trusted_cert copy script generation on windows

## Release 1.7.0

* [knife-windows #400](https://github.com/chef/knife-windows/pull/400) Allow a custom codepage to be specified and passed to the cmd shell

## Release 1.6.0

* [knife-windows #393](https://github.com/chef/knife-windows/pull/393) Add documentation of the --msi-url option
* [knife-windows #392](https://github.com/chef/knife-windows/pull/392) Use winrm v2 and allow users to pass a shell
* [knife-windows #388](https://github.com/chef/knife-windows/pull/388) fix #386 swallowing node_ssl_verify_mode value
* [knife-windows #385](https://github.com/chef/knife-windows/pull/385) Fixed win 2008 64bit ssh bootstrap command hanging
* [knife-windows #384](https://github.com/chef/knife-windows/pull/384) Fix for architechture detection issue for 64 bit
* [knife-windows #381](https://github.com/chef/knife-windows/pull/381) Add validation for FQDN value
* [knife-windows #380](https://github.com/chef/knife-windows/pull/380) Fixing bootstrap via ssh regression

## Release 1.5.0

* [knife-windows #377](https://github.com/chef/knife-windows/pull/377) Added code and corresponding RSpecs to read the json attributes from the --json-attributes-file option.

## Release 1.4.1

* [knife-windows #362](https://github.com/chef/knife-windows/pull/362) Fix `knife windows bootstrap` chef client downloads over a proxy
* [knife-windows #367](https://github.com/chef/knife-windows/pull/367) Honor chef's ssl_policy when making winrm calls

## Release 1.4.0

* [knife-windows #354](https://github.com/chef/knife-windows/pull/354) Allows the user to specify the architecture they want to install on the target system during `knife bootstrap windows`.  In your knife config specify `knife[:bootstrap_architecture]`.  Valid values are `:i386` for 32 bit or `:x86_64` for 64 bit.  By default the architecture will be whatever the target system is.  If you try to install a 64 bit package on a 32 bit system you will receive an error.
* [knife-windows #352](https://github.com/chef/knife-windows/pull/352) Have client.rb verify that FIPS mode can be enforced

## Release 1.3.0
* [knife-windows #349](https://github.com/chef/knife-windows/pull/349) Pulls in Winrm 1.7.0 which now consumes rubyntlm 0.6.0 to support Extended Protection for Authentication (aka channel binding) for NTLM over TLS
* [knife-windows #350](https://github.com/chef/knife-windows/pull/350) Adding a `--ssl-peer-fingerprint` option as an alternative to `--winrm-ssl-verify-mode verify_none` in self signed scenarios

## Release 1.2.1
* [knife-windows #341](https://github.com/chef/knife-windows/pull/341) Removes nokogiri dependency and adds UX fixes for `knife wsman test` when probing a SSL endpoint configured with a self signed certificate

## Release 1.2.0
* [knife-windows #334](https://github.com/chef/knife-windows/pull/334) Uses Negotiate authentication via winrm 1.6 on both windows and linux and drops winrm-s dependency

## Release 1.1.4
* Bumps winrm-s and winrm dependencies to address a winrm-s incompatibility bug with winrm 1.5

## Release 1.1.3
* [knife-windows #329](https://github.com/chef/knife-windows/pull/329) Pin to a minimum winrm-s of 0.3.2 addressing encoding issues in 0.3.1

## Release 1.1.2
* [knife-windows #317](https://github.com/chef/knife-windows/pull/317) Update Vault after client is created
* [knife-windows #325](https://github.com/chef/knife-windows/pull/325) Fix proxy configuration to work with chef client 12.6.0
* [knife-windows #326](https://github.com/chef/knife-windows/pull/326) Support new `ssh_identity_file` bootstrap argument

## Release 1.1.1
* [knife-windows #307](https://github.com/chef/knife-windows/pull/307) Ensure prompted password is passed to winrm session
* [knife-windows #311](https://github.com/chef/knife-windows/issues/311) WinRM bootstrap silently fails

## Release 1.1.0
* [knife-windows #302](https://github.com/chef/knife-windows/pull/302) Address regression caused by chef client 12.5 environment argument
* [knife-windows #295](https://github.com/chef/knife-windows/issues/295) Bootstrap missing policy_group, policy_name feature from Chef Client 12.5
* [knife-windows #296](https://github.com/chef/knife-windows/issues/296) Installing knife-windows produces warning for _all_ knife commands in Mac OS X with ChefDK 0.8.0
* [knife-windows #297](https://github.com/chef/knife-windows/pull/297) use configured proxy settings for all winrm sessions

## Release 1.0.0

* [knife-windows #281](https://github.com/chef/knife-windows/pull/281) Prevent unencrypted negotiate auth, automatically prefix local usernames with '.' for negotiate
* [knife-windows #275](https://github.com/chef/knife-windows/pull/275) Added bootstrap\_install\_command option in parity with knife bootstrap
* [knife-windows #240](https://github.com/chef/knife-windows/pull/240) Change kerberos keytab short option to -T to resolve conflict
* [knife-windows #232](https://github.com/chef/knife-windows/pull/232) Adding --hint option to bootstrap
* [knife-windows #227](https://github.com/chef/knife-windows/issues/227) Exception: NoMethodError: undefined method 'gsub' for false:FalseClass
* [knife-windows #222](https://github.com/chef/knife-windows/issues/222) Validatorless bootstrap support
* [knife-windows #202](https://github.com/chef/knife-windows/issues/202) knife bootstrap windows should support enabling the service
* [knife-windows #213](https://github.com/chef/knife-windows/pull/213) Search possibilities of HOME for bootstrap templates
* [knife-windows #206](https://github.com/chef/knife-windows/pull/206) Add a flag msi_url that allows one to fetch the Chef client msi from a non-chef.io path
* [knife-windows #192](https://github.com/chef/knife-windows/issues/192) deprecate knife bootstrap --distro
* [knife-windows #159](https://github.com/chef/knife-windows/issues/159) `winrm_port` option should default to 5986 if `winrm_transport` option is `ssl`
* [knife-windows #149](https://github.com/chef/knife-windows/pull/149) Adding knife wsman test to validate WSMAN/WinRM availability
* [knife-windows #139](https://github.com/chef/knife-windows/issues/139) Force dev dependency on Chef 11 for test scenarios to avoid Ohai 8 conflict on Ruby 1.9.x
* [knife-windows #126](https://github.com/chef/knife-windows/pull/126) Allow disabling of SSL peer verification in knife-windows for testing
* [knife-windows #154](https://github.com/chef/knife-windows/issues/154) Unreleased regression in master: NameError: undefined local variable or method `path_separator
* [knife-windows #143](https://github.com/chef/knife-windows/issues/143) Unreleased regression in master: WinRM::WinRMHTTPTransportError: Bad HTTP response returned from server (503) in the middle of bootstrap
* [knife-windows #133](https://github.com/chef/knife-windows/issues/133) Bootstrap failure -- unable to validate SSL chef server endpoints
* [knife-windows #132](https://github.com/chef/knife-windows/issues/132) New subcommands for WinRM: windows listener create, cert generate, and cert install
* [knife-windows #129](https://github.com/chef/knife-windows/issues/129) New --winrm-authentication-protocol option for explicit control of authentication
* [knife-windows #125](https://github.com/chef/knife-windows/issues/125) knife-windows should use PowerShell first before cscript to download the  Chef Client msi
* [knife-windows #92](https://github.com/chef/knife-windows/issues/92) EventMachine issue: knife bootstrap windows winrm error
* [knife-windows #94](https://github.com/chef/knife-windows/issues/94) Remove Eventmachine dependency
* [knife-windows #252](https://github.com/chef/knife-windows/pull/252) Fail early on ECONNREFUSED, Closes #244.
* [knife-windows #260](https://github.com/chef/knife-windows/pull/260) Fail quickly on invalid option combinations, Closes #259

## Release: 0.8.5
* [knife-windows #228](https://github.com/chef/knife-windows/pull/228) make winrm-s dep more strict on knife-windows 0.8.x

## Release: 0.8.4
* [knife-windows #133](https://github.com/chef/knife-windows/issues/133) Bootstrap failure -- unable to validate SSL chef server endpoints

## Release: 0.8.3
* [knife-windows #131](https://github.com/chef/knife-windows/issues/108) Issue #131: Windows should be bootstrapped using latest Chef Client version compatible with knife's version just like non-Windows systems
* [knife-windows #139](https://github.com/chef/knife-windows/issues/139) Force dev dependency on Chef 11 for test scenarios to avoid Ohai 8 conflict on Ruby 1.9.x

## Release: 0.8.2
* [knife-windows #108](https://github.com/chef/knife-windows/issues/108) Error: Unencrypted communication not supported if remote server does not require encryption

## Release: 0.8.0
* [knife-windows #98](https://github.com/chef/knife-windows/issues/98) Get winrm command exit code if it is not expected
* [knife-windows #96](https://github.com/chef/knife-windows/issues/96) Fix break from OS patch KB2918614
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