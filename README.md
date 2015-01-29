Knife Windows Plugin
====================

This plugin adds additional functionality to the Chef Knife CLI tool for
configuring/interacting with nodes running Microsoft Windows. The subcommands
should function on any system running Ruby 1.9.1+ but nodes being configured
via these subcommands require Windows Remote Management (WinRM) 1.0+.WinRM
allows you to call native objects in Windows. This includes, but is not
limited to, running batch scripts, powershell scripts and fetching WMI
variables. For more information on WinRM, please visit
[Microsoft's WinRM site](http://msdn.microsoft.com/en-us/library/aa384426(v=VS.85).aspx).
You will want to familiarize yourself with (certain key aspects) of WinRM
because you will be writing scripts / running commands with this tool to get
you from specific point A to specific point B.

WinRM is built into Windows 7 and Windows Server 2008+. It can also be easily installed on older version of Windows, including:

* Windows Server 2003
* Windows Vista

More information can be found on [Microsoft Support article 968930](http://support.microsoft.com/?kbid=968930).

## Subcommands

This plugin provides the following Knife subcommands. Specific command options can be found by invoking the subcommand with a `--help` flag

### knife winrm

The `winrm` subcommand allows you to invoke commands in parallel on a subset of the nodes in your infrastructure. The `winrm` subcommand uses the same syntax as the [search subcommand](http://wiki.opscode.com/display/chef/Search); you could could find the uptime of all your web servers using the command:

    knife winrm "role:web" "net stats srv" -x Administrator -P 'super_secret_password'

Or force a chef run:

    knife winrm 'ec2-50-xx-xx-124.compute-1.amazonaws.com' 'chef-client -c c:/chef/client.rb' -m -x Administrator -P 'super_secret_password'
    ec2-50-xx-xx-124.compute-1.amazonaws.com [Fri, 04 Mar 2011 22:00:49 +0000] INFO: Starting Chef Run (Version 0.9.12)
    ec2-50-xx-xx-124.compute-1.amazonaws.com [Fri, 04 Mar 2011 22:00:50 +0000] WARN: Node ip-0A502FFB has an empty run list.
    ec2-50-xx-xx-124.compute-1.amazonaws.com [Fri, 04 Mar 2011 22:00:53 +0000] INFO: Chef Run complete in 4.383966 seconds
    ec2-50-xx-xx-124.compute-1.amazonaws.com [Fri, 04 Mar 2011 22:00:53 +0000] INFO: cleaning the checksum cache
    ec2-50-xx-xx-124.compute-1.amazonaws.com [Fri, 04 Mar 2011 22:00:53 +0000] INFO: Running report handlers
    ec2-50-xx-xx-124.compute-1.amazonaws.com [Fri, 04 Mar 2011 22:00:53 +0000] INFO: Report handlers complete

This subcommand operates in a manner similar to [knife ssh](http://wiki.opscode.com/display/chef/Knife#Knife-SSHSubcommand)...just leveraging the WinRM protocol for communication. It also include's `knife ssh`'s "[interactive session mode](http://wiki.opscode.com/display/chef/Knife#Knife-InteractiveMode)"

### knife bootstrap windows winrm

Performs a Chef Bootstrap (via the WinRM protocol) on the target node. The goal of the bootstrap is to get Chef installed on the target system so it can run Chef Client with a Chef Server. The main assumption is a baseline OS installation exists. It is primarily intended for Chef Client systems that talk to a Chef server.

This subcommand operates in a manner similar to [knife bootstrap](http://wiki.opscode.com/display/chef/Knife+Bootstrap)...just leveraging the WinRM protocol for communication. An initial run_list for the node can also be passed to the subcommand. Example usage:

    knife bootstrap windows winrm ec2-50-xx-xx-124.compute-1.amazonaws.com -r 'role[webserver],role[production]' -x Administrator -P 'super_secret_password'

### knife bootstrap windows ssh

Performs a Chef Bootstrap (via the SSH protocol) on the target node. The goal of the bootstrap is to get Chef installed on the target system so it can run Chef Client with a Chef Server. The main assumption is a baseline OS installation exists. It is primarily intended for Chef Client systems that talk to a Chef server.

This subcommand assumes the SSH session will use the Windows native cmd.exe command shell vs a bash shell through an emulated cygwin layer. Most popular Windows based SSHd daemons like [freeSSHd](http://www.freesshd.com/) and [WinSSHD](http://www.bitvise.com/winsshd) behave this way.

An initial run_list for the node can also be passed to the subcommand. Example usage:

    knife bootstrap windows ssh ec2-50-xx-xx-124.compute-1.amazonaws.com -r 'role[webserver],role[production]' -x Administrator -i ~/.ssh/id_rsa

### knife windows cert generate

Generates a certificate(x509) containing a public / private key pair for WinRM 'SSL' communication.
The certificate will be generated in three different formats *.pfx, *.b64 and *.pem.
The PKCS12(i.e *.pfx) contains both the public and private keys, usually used on the server. This will be added to WinRM Server's Certificate Store.
The *.b64 is Base64 PKCS12 keypair. Contains both the public and private keys, for upload to the Cloud REST API. e.g. Azure.
The *.pem is Base64 encoded public certificate only. Required by the client to connect to the server.
This command also displays the thumbprint of the generated certificate.

    knife windows cert generate --cert-passphrase "strong_passphrase" --domain "cloudapp.net" --output-file "~/server_cert.pfx"
    # This command will generate certificates at user's home directory with names server_cert.b64, server_cert.pfx and server_cert.pem.

### knife windows cert install

This command only functions on Windows. It adds the specified certificate to its certificate store. This command must include a valid PKCS12(i.e *.pfx) certificate file path.

    knife windows cert install "~/server_cert.pfx" --cert-passphrase "strong_passphrase"

### knife windows listener create
This command only functions on Windows. It creates the winrm listener for SSL communication(i.e HTTPS).
This command can also install certificate which is specified using --cert-install option and use the installed certificate thumbprint to create winrm listener.
--hostname option is optional. Default value for hostname is *.

    knife windows listener create --cert-passphrase "strong_passphrase" --hostname "*.cloudapp.net" --cert-install "~/server_cert.pfx"

The command also allows you to use existing certificates from local store to create winrm listener. Use --cert-thumbprint option to specify the certificate thumbprint.

    knife windows listener create --cert-passphrase "strong_passphrase" --hostname "*.cloudapp.net" --cert-thumbprint "bf0fef0bb41be40ceb66a3b38813ca489fe99746"

You can get the thumbprint for existing certificates in local store using the following powershell command:

    Get-ChildItem -path cert:\LocalMachine\My

## BOOTSTRAP TEMPLATES:

This gem provides the bootstrap template `windows-chef-client-msi`.

### windows-chef-client-msi

This bootstrap template does the following:

* Installs the latest version of Chef (and all dependencies) using the `chef-client` msi.
* Writes the validation.pem per the local knife configuration.
* Writes a default config file for Chef (`C:\chef\client.rb`) using values from the `knife.rb`.
* Creates a JSON attributes file containing the specified run list and run Chef.

This is the default bootstrap template used by both the `windows bootstrap` subcommands.

## REQUIREMENTS/SETUP:

### Ruby

Ruby 1.9.1+ is needed.

### Chef Version

Knife plugins require >= Chef 0.10. More details about Knife plugins can be [found on the Chef wiki](http://wiki.opscode.com/display/chef/Knife+Plugins).

## Nodes

**NOTE**: Before any WinRM related knife subcommands will function correctly a node's WinRM installation must be configured correctly. The below settings should be added to your base server image (AMI) or passed in using some sort of user-data mechanism provided by your cloud provider.

A server running WinRM must also be configured properly to allow outside connections and the entire network path from the knife workstation to the server. The easiest way to accomplish this is to use [WinRM's quick configuration option](http://msdn.microsoft.com/en-us/library/aa384372(v=vs.85).aspx#quick_default_configuration):

    winrm quickconfig -q

The Chef and Ohai gem installations (that occur during bootstrap) take more
memory than the default 150MB WinRM allocates per shell -- this can slow down
bootstrap. Optionally increase the memory limit to 300MB with the following command:

    winrm set winrm/config/winrs @{MaxMemoryPerShellMB="300"}

Bootstrap commands can take longer than the WinRM default 60 seconds to
complete, optionally increase to 30 minutes if bootstrap terminates a command prematurely:

    winrm set winrm/config @{MaxTimeoutms="1800000"}

WinRM supports both the HTTP and HTTPS transports and the following
authentication schemes: Kerberos, Digest, Certificate and Basic.  The details
of these authentication transports are outside of the scope of this README but
details can be found on the
[WinRM configuration guide](http://msdn.microsoft.com/en-us/library/aa384372(v=vs.85).aspx).
Currently, this plugin support Kerberos and Basic authentication schemes on
all platform versions. The negotiate protocol which allows NTLM is fully
supported when `knife windows bootstrap` is executed on a Windows system; if
it is executed on a non-Windows system, certificate authentication or Kerberos
should be used instead via the `:kerberos_service` and related options of the subcommands.

**NOTE**: In order to use NTLM / Negotiate to authenticate as the user
  specified by the `--winrm-user` (`-x`) option, you must include the user's
  Windows domain when specifying the user name using the format `domain\user`
  where the backslash ('`\`') character separates the user from the domain. If
  an account local to the node is being used to access, `.` may be used as the domain:

    knife bootstrap windows winrm web1.cloudapp.net -r 'server::web' -x 'proddomain\webuser' -P 'super_secret_password'
    knife bootstrap windows winrm db1.cloudapp.net -r 'server::db' -x '.\localadmin' -P 'super_secret_password'

For development and testing purposes, unencrypted traffic with Basic authentication can make it easier to test connectivity:

    winrm set winrm/config/service @{AllowUnencrypted="true"}
    winrm set winrm/config/service/auth @{Basic="true"}

## Troubleshooting

* When I run the winrm command I get: "Error: Invalid use of command line. Type "winrm -?" for help."
  You're running the winrm command from PowerShell and you need to put the key/value pair in single quotes. For example:

    winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="512"}'

* Windows 2008r2 and earlier versions require an extra configuration for MaxTimeoutms to avoid WinRM::WinRMHTTPTransportError: Bad HTTP response error. It should be greater than 30000.

    winrm set winrm/config @{MaxTimeoutms=300000}

## CONTRIBUTING:

Please file bugs against the KNIFE_WINDOWS project at https://github.com/opscode/knife-windows/issues.

More information on the contribution process for Opscode projects can be found in the [Chef Contributions document](http://docs.opscode.com/community_contributions.html).

# LICENSE:

Author:: Seth Chisamore (<schisamo@opscode.com>)
Copyright:: Copyright (c) 2014 Opscode, Inc.
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
