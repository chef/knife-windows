Knife Windows Plugin
====================
[![Build Status Master](https://travis-ci.org/chef/knife-windows.svg?branch=master)](https://travis-ci.org/chef/knife-windows)
[![Build Status Master](https://ci.appveyor.com/api/projects/status/github/chef/knife-windows?branch=master&svg=true&passingText=master%20-%20Ok&pendingText=master%20-%20Pending&failingText=master%20-%20Failing)](https://ci.appveyor.com/project/Chef/knife-windows/branch/master)
[![Gem Version](https://badge.fury.io/rb/knife-windows.svg)](https://badge.fury.io/rb/knife-windows)

This plugin adds additional functionality to the Chef Knife CLI tool for
configuring / interacting with nodes running Microsoft Windows:

* Bootstrap of nodes via the [Windows Remote Management (WinRM)](http://msdn.microsoft.com/en-us/library/aa384426\(v=VS.85\).aspx) or SSH protocols
* Remote command execution using the WinRM protocol
* Utilities to configure WinRM SSL endpoints on managed nodes

## Subcommands

This plugin provides the following Knife subcommands. Specific command options can be found by invoking the subcommand with a `--help` flag

### knife winrm

The `winrm` subcommand allows you to invoke commands in parallel on a subset of the nodes in your infrastructure. The `winrm` subcommand uses the same syntax as the [search subcommand](https://docs.chef.io/knife_search.html); you could could find the uptime of all your web servers using the command:

    knife winrm "role:web" "net stats srv" -x Administrator -P 'super_secret_password'

Or force a chef run:

    knife winrm "myserver.myorganization.net" "chef-client -c c:/chef/client.rb" -m -x Administrator -P "super_secret_password"
    myserver.myorganization.net [Fri, 04 Mar 2011 22:00:49 +0000] INFO: Starting Chef Run (Version 0.9.12)
    myserver.myorganization.net [Fri, 04 Mar 2011 22:00:50 +0000] WARN: Node ip-0A502FFB has an empty run list.
    myserver.myorganization.net [Fri, 04 Mar 2011 22:00:53 +0000] INFO: Chef Run complete in 4.383966 seconds
    myserver.myorganization.net [Fri, 04 Mar 2011 22:00:53 +0000] INFO: cleaning the checksum cache
    myserver.myorganization.net [Fri, 04 Mar 2011 22:00:53 +0000] INFO: Running report handlers
    myserver.myorganization.net [Fri, 04 Mar 2011 22:00:53 +0000] INFO: Report handlers complete

This subcommand operates in a manner similar to [knife ssh](https://docs.chef.io/knife_ssh.html)...just leveraging the WinRM protocol for communication. It also includes `knife ssh`'s "[interactive session mode](https://docs.chef.io/knife_ssh.html#options)"

### knife bootstrap windows winrm

Performs a Chef Bootstrap (via the WinRM protocol) on the target node. The goal of the bootstrap is to get Chef installed on the target system so it can run Chef Client with a Chef Server. The main assumption is a baseline OS installation exists. It is primarily intended for Chef Client systems that talk to a Chef server.

This subcommand operates in a manner similar to [knife bootstrap](https://docs.chef.io/knife_bootstrap.html)...just leveraging the WinRM protocol for communication. An initial run_list for the node can also be passed to the subcommand. Example usage:

    knife bootstrap windows winrm myserver.myorganization.net -r 'role[webserver],role[production]' -x Administrator -P 'super_secret_password'

#### Tip: Use SSL for WinRM communication

By default, the `knife winrm` and `knife bootstrap windows winrm` subcommands use a plaintext transport,
but they support an option `--winrm-transport` (or `-t`) with the argument
`ssl` that allows the SSL to secure the WinRM payload. Here's an example:

    knife winrm -t ssl "role:web" "net stats srv" -x Administrator -P "super_secret_password" -f ~/server_public_cert.crt

Use of SSL is strongly recommended, particularly when invoking `knife-windows` on non-Windows platforms, since
without SSL there are limited options for ensuring the privacy of the
plaintext transport. See the section on [Platform authentication
support](#platform-winrm-authentication-support).

SSL will become the default transport in future revisions of
`knife-windows`.

#### Specifying the package architecture

You can configure which package architecture (32 bit or 64 bit) to install on the bootstrapped system.  In your knife config specify `knife[:bootstrap_architecture]`.  Valid values are `:i386` for 32 bit or `:x86_64` for 64 bit.  By default the architecture will be whatever the target system is.  If you try to install a 64 bit package on a 32 bit system you will receive an error, but installing a 32 bit package on a 64 bit system is supported.

Currently (March 2016) the `stable` channel of omnibus (where downloads using the install script fetch) only has 32 bit packages but this will be updated soon to include both 32 and 64 bit packages.  Until then you will need to access the `current` channel by specifying `--prerelease` in your `knife bootstrap windows` if you want 64 bit packages.

### knife wsman test

Connects to the remote WSMan/WinRM endpoint and verifies the remote node is listening.  This is the equivalent of running Test-Wsman from PowerShell.  Endpoints to test can be specified manually, or be driven by search and use many of the same connection options as knife winrm.
To test a single node using the default WinRM port (5985)

    knife wsman test 192.168.1.10 -m

or to test a single node with SSL enabled on the default port (5986)

    knife wsman test 192.168.1.10 -m --winrm-transport ssl

or to test all windows nodes registered with your Chef Server organization

    knife wsman test platform:windows

### knife bootstrap windows ssh

Performs a Chef Bootstrap (via the SSH protocol) on the target node. The goal of the bootstrap is to get Chef installed on the target system so it can run Chef Client with a Chef Server. The main assumption is a baseline OS installation exists. It is primarily intended for Chef Client systems that talk to a Chef server.

This subcommand assumes the SSH session will use the Windows native cmd.exe command shell vs a bash shell through an emulated cygwin layer. Most popular Windows based SSHd daemons like [freeSSHd](http://www.freesshd.com/) and [WinSSHD](http://www.bitvise.com/winsshd) behave this way.

An initial run_list for the node can also be passed to the subcommand. Example usage:

    knife bootstrap windows ssh myserver.myorganization.net -r "role[webserver],role[production]" -x Administrator -i ~/.ssh/id_rsa

### knife windows cert generate

Generates a certificate(x509) containing a public / private key pair for WinRM 'SSL' communication.
The certificate will be generated in three different formats:
* **.pem** - The *.pem is Base64 encoded public certificate only. One can use this file with the `-f` argument on `knife bootstrap windows winrm` and `knife winrm` commands.
* **.pfx** - The PKCS12(i.e .pfx) contains both the public and private keys, usually used on the server. This can be added to a WinRM Server's Certificate Store using `knife windows cert install` (see command description below). **Note:** Do not use the *.pfx file with the `-f` argument on the `knife bootstrap windows winrm` and `knife winrm` commands. Use the *.pem file instead.
* **.b64** - The *.b64 is Base64 PKCS12 key pair. Contains both the public and private keys, for upload to the Cloud REST API. e.g. Azure.

This command also displays the thumbprint of the generated certificate.

    knife windows cert generate --cert-passphrase "strong_passphrase" --hostname "myserver.myorganization.net" --output-file "~/server_cert.pfx"
    # This command will generate certificates in the user's home directory with names server_cert.b64, server_cert.pfx and server_cert.pem.

### knife windows cert install

This command only functions on Windows and is intended to be run on a chef node. It adds the specified certificate to its certificate store. This command must include a valid PKCS12(i.e *.pfx) certificate file path such as the *.pfx file generated by `knife windows cert generate` described above.

    knife windows cert install "~/server_cert.pfx" --cert-passphrase "strong_passphrase"

### knife windows listener create
This command only functions on Windows and is intended to be run on a chef node. It creates the winrm listener for SSL communication(i.e HTTPS).
This command can also install certificate which is specified using --cert-install option and use the installed certificate thumbprint to create winrm listener.
--hostname option is optional. Default value for hostname is *.

    knife windows listener create --cert-passphrase "strong_passphrase" --hostname "myserver.mydomain.net" --cert-install "~/server_cert.pfx"

The command also allows you to use existing certificates from local store to create winrm listener. Use --cert-thumbprint option to specify the certificate thumbprint.

    knife windows listener create --cert-passphrase "strong_passphrase" --hostname "myserver.mydomain.net" --cert-thumbprint "bf0fef0bb41be40ceb66a3b38813ca489fe99746"

You can get the thumbprint for existing certificates in the local store using the following PowerShell command:

    ls cert:\LocalMachine\My

## Bootstrap template

This gem provides the bootstrap template `windows-chef-client-msi`,
which does the following:

* Installs the latest version of Chef Client (and all dependencies) using the `chef-client` msi.
* Writes the validation.pem per the local knife configuration.
* Writes a default config file for Chef (`C:\chef\client.rb`) using values from the `knife.rb`.
* Creates a JSON attributes file containing the specified run list and run Chef.

This template is used by both `knife bootstrap windows winrm` and `knife bootstrap windows ssh` subcommands.

## Requirements / setup

### Ruby

Ruby 1.9.3+ is required.

### Chef version

This knife plugins requires >= Chef 11.0.0. More details about Knife plugins can be
[found in the Chef documentation](https://docs.chef.io/plugin_knife.html).

## Nodes

### WinRM versions

The node must be running Windows Remote Management (WinRM) 2.0+. WinRM
allows you to call native objects in Windows. This includes, but is not
limited to, running PowerShell scripts, batch scripts, and fetching WMI
data. For more information on WinRM, please visit
[Microsoft's WinRM site](http://msdn.microsoft.com/en-us/library/aa384426\(v=VS.85\).aspx).

WinRM is built into Windows 7 and Windows Server 2008+. It can also [be installed](https://support.microsoft.com/en-us/kb/968929) on older version of Windows, including:

* Windows Server 2003
* Windows Vista

### WinRM configuration

**NOTE**: Before any WinRM related knife subcommands will function
  a node's WinRM installation must be configured correctly.
  The settings below must be added to your base server image or passed
  in using some sort of user-data mechanism provided by your cloud
  provider. Some cloud providers will set up the required WinRM
  configuration through the cloud API for creating instances -- see
  the documentation for the provider.

A server running WinRM must also be configured properly to allow
outside connections for the entire network path from the knife workstation to the server. The easiest way to accomplish this is to use [WinRM's quick configuration option](http://msdn.microsoft.com/en-us/library/aa384372\(v=vs.85\).aspx#quick_default_configuration):

    winrm quickconfig -q

This will set up an WinRM listener using the HTTP (plaintext)
transport -- WinRM also supports the SSL transport for improved
robustness against information disclosure and other threats.

The chef-client installation and bootstrap may take more
memory than the default 150MB WinRM allocates per shell on older versions of
Windows (prior to Windows Server 2012) -- this can slow down
bootstrap or cause it to fail. The memory limit was increased to 1GB with Windows Management Framework 3
(and Server 2012). However, there is a bug in Windows Management Framework 3
(and Server 2012) which requires a [hotfix from Microsoft](https://support.microsoft.com/en-us/kb/2842230/en-us).
You can increase the memory limit to 1GB with the following PowerShell
command:

```powershell
    set-item wsman:\localhost\shell\maxmemorypershellmb 1024
```

Bootstrap commands can take longer than the WinRM default 60 seconds to
complete, optionally increase to 30 minutes if bootstrap terminates a command prematurely:

```powershell
    set-item wsman:\localhost\MaxTimeoutms 300000
```

Note that the `winrm` command itself supports the same configuration
capabilities as the PowerShell commands given above -- if you need to
configure WinRM without using PowerShell, use `winrm -?` to get help.

WinRM supports both the HTTP and HTTPS (SSL) transports and the following
authentication schemes: Kerberos, Digest, Certificate and Basic. The details
of these authentication transports are outside of the scope of this
README but details can be found on the
[WinRM configuration guide](http://msdn.microsoft.com/en-us/library/aa384372\(v=vs.85\).aspx).

#### Configure SSL on a Windows node

WinRM supports use of SSL to provide privacy and integrity of
communication using the protocol and to prevent spoofing attacks.

##### Configure SSL using `knife`

`knife-windows` includes three commands to assist with SSL
configuration -- these commands support all versions of Windows and do
not rely on PowerShell:

* `knife windows cert generate`: creates a certificate that may be used
  to configure an SSL WinRM listener

* `knife windows cert install`: Installs a certificate into the
  Windows certificate store so it can be used to configure an SSL
  WinRM listener.

* `knife windows listener create`: Creates a WinRM listener on a
  Windows node -- it can use either a certificate already installed in
  the Windows certificate store, or one created by other tools
  including the `knife windows cert generate` command.

Here is an example that configures a listener on the node on which the
commands are executed:

    knife windows cert generate --domain myorg.org --output-file $env:userprofile/winrmcerts/winrm-ssl
    knife windows listener create --hostname *.myorg.org --cert-install $env:userprofile/winrmcerts/winrm-ssl.pfx

Note that the first command which generates the certificate for the
listener could be executed from any system that can run `knife` as
long as the certificate it generates is made available at a path at
which the second command can access it.

See previous sections for additional details of the `windows cert generate`, `windows cert install` and `windows listener create` subcommands.

##### Configure SSL using *Windows Server 2012 or later*
The following PowerShell commands may be used to create an SSL WinRM
listener with a self-signed certificate on Windows 2012R2 or later systems:

```powershell
$cert = New-SelfSignedCertificate -DnsName 'myserver.mydomain.org' -CertStoreLocation Cert:\LocalMachine\My
new-item -address * -force -path wsman:\localhost\listener -port 5986 -hostname ($cert.subject -split '=')[1] -transport https -certificatethumbprint $cert.Thumbprint
# Open the firewall for 5986, the default WinRM SSL port
netsh advfirewall firewall set rule name="Windows Remote Management (HTTPS-In)" profile=public protocol=tcp localport=5986 remoteip=localsubnet new remoteip=any

```

Note that the first command which uses the `New-SelfSignedCertificate`
cmdlet is available only in PowerShell version 4.0 and later.

##### Configure SSL using `winrm quickconfig`

The following command can configure an SSL WinRM listener if the
Windows certificate store's Local Machine store contains a certificate
that meets certain criteria that are most likely to be met if the
system is joined to a Windows Active Directory domain:

    winrm quickconfig -transport:https -q

If the criteria are not met, an error message will follow with
guidance on the certificate requirements; you may need to obtain a
certificate from the appropriate source or use the PowerShell or
`knife` techniques given above to create the listener instead.

##### Disabling peer verification
In the SSL examples above, the `-f` parameter was used to supply a
certificate that could validate the identity of the remote server.
For debugging purposes, this validation may be skipped if you have not
obtained a public certificate that can validate the server. Here is an
example:

    knife winrm -m 192.168.0.6 -x "mydomain\myuser" -P $PASSWD -t ssl --winrm-ssl-verify-mode verify_none ipconfig

This option should be used carefully since disabling the verification of the
remote system's certificate can subject knife commands to spoofing attacks.

##### Connecting securely to self-signed certs
If you generate a self-signed cert, the fqdn and ip may not match which will result in a certificate validation failure. In order to securely connect and reduce the risk of a "Man In The Middle" attack, you may use the certificate's fingerprint to precisely identify the known certificate on the WinRM endpoint.

The fingerprint can be supplied to ```--ssl-peer-fingerprint``` and instead of using a certificate chain and comparing the CommonName, it will only verify that the fingerprint matches:

    knife winrm --ssl-peer-fingerprint 89255929FB4B5E1BFABF7E7F01AFAFC5E7003C3F \
		      -m $IP -x Administrator -P $PASSWD-t ssl --winrm-port 5986 hostname
		10.113.4.54 ip-0A710436

## WinRM authentication

The default authentication protocol for `knife-windows` subcommands that use
WinRM is the Negotiate protocol. The following commands show authentication for domain and local accounts respectively:

    knife bootstrap windows winrm web1.cloudapp.net -r "server::web" -x "proddomain\webuser" -P "super_secret_password"
    knife bootstrap windows winrm db1.cloudapp.net -r "server::db" -x "localadmin" -P "super_secret_password"

The remote system may also be configured with an SSL WinRM listener instead of a
plaintext listener. Then the above commands should be modified to use the SSL
transport as follows using the `-t` (or `--winrm-transport`) option with the
`ssl` argument:

    knife bootstrap windows winrm -t ssl web1.cloudapp.net -r "server::web" -x "proddomain\webuser" -P "super_secret_password" -f ~/mycert.crt
    knife bootstrap windows winrm -t ssl db1.cloudapp.net -r "server::db" -x "localadmin" -P "super_secret_password" ~/mycert.crt

### Troubleshooting authentication

Unencrypted traffic with Basic authentication should only be used for low level wire protocol debugging. The configuration for plain text connectivity to
the remote system may be accomplished with the following PowerShell commands:

```powershell
set-item wsman:\localhost\service\allowunencrypted $true
set-item wsman:\localhost\service\auth\basic $true
```
To use basic authentication connectivity via `knife-windows`, the default
authentication protocol of Negotiate must be overridden using the
`--winrm-authentication-protocol` option with the desired protocol, in this
case Basic:

    knife winrm -m web1.cloudapp.net --winrm-authentication-protocol basic ipconfig -x localadmin -P "super_secret_password"

Note that when using Basic authentication, domain accounts may not be used for
authentication; an account local to the remote system must be used.

### Platform WinRM authentication support

`knife-windows` supports `Kerberos`, `Negotiate`, and `Basic` authentication
for WinRM communication.

The following table shows the authentication protocols that can be used with
`knife-windows` depending on whether the knife workstation is a Windows
system, the transport, and whether or not the target user is a domain user or
local to the target Windows system.

> \* There is a known defect in the `knife winrm` and `knife bootstrap windows
> winrm` subcommands invoked on any OS  platform when authenticating with the Negotiate protocol over
> the SSL transport. The defect is tracked by
> [knife-windows issue #176](https://github.com/chef/knife-windows/issues/176): If the remote system is
> domain-joined, local accounts may not be used to authenticate via Negotiate
> over SSL -- only domain accounts will work. Local accounts will only
> successfully authenticate if the system is not joined to a domain.
>
> This is generally not an issue for bootstrap scenarios, where the
> system has yet to be joined to any domain, but can be a problem for remote
> management cases after the system is domain joined. Workarounds include using
> a domain account instead or bypassing SSL and using Negotiate authentication.

## General troubleshooting

* Windows 2008R2 and earlier versions require an extra configuration
  for MaxTimeoutms to avoid WinRM::WinRMHTTPTransportError: Bad HTTP
  response error while bootstrapping. It should be at least 300000.

  `set-item wsman:\\localhost\\MaxTimeoutms 300000`

* When I run the winrm command I get: "Error: Invalid use of command line. Type "winrm -?" for help."
  You're running the winrm command from PowerShell and you need to put the key/value pair in single quotes. For example:

   `winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="1024"}'`


## CONTRIBUTING:

Please file bugs against the KNIFE_WINDOWS project at https://github.com/chef/knife-windows/issues.

More information on the contribution process for Chef projects can be found in the [Chef Contributions document](http://docs.chef.io/community_contributions.html).

# LICENSE:

Author:: Seth Chisamore (<schisamo@chef.io>)
Copyright:: Copyright (c) 2015-2016 Chef Software, Inc.
License:: Apache License, Version 2.0

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
