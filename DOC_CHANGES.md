<!---
This file is reset every time a new release is done. This file describes changes that have not yet been released.

Example Doc Change:
### Headline for the required change
Description of the required change.
-->
# knife-windows 1.0.0 doc changes

### New bootstrap download and installation options
The following commands enable alternate ways to download and install
Chef Client during bootstrap:

* `--msi-url URL`: Optional. Used to override the location from which Chef
  Client is downloaded. If not specified, Chef Client is downloaded
  from the Internet -- this option allows downloading from a private network
  location for instance.
* `--install-as-service`: Optional. Install chef-client as a Windows service
* `--bootstrap-install-command`: Optional. Instead of downloading Chef
  Client and installing it using a default installation command,
  bootstrap will invoke this command. If an image already has
  Chef Client installed, this command can be specified as empty
  (`''`), in which case no installation will be done and the rest of
  bootstrap will proceed as if it's already installed.

### WinRM default port default change
The `winrm_port` option specifies the TCP port on the remote system to which
to connect for WinRM communication for `knife-windows` commands that use
WinRM. The default value of this option is **5986** if the WinRM transport
(configured by the `winrm_transport` option) is SSL, otherwise it is **5985**.
These defaults correspond to the port assignment conventions for the WinRM
protocol, which is also honored by WinRM tools built-in to Windows such as the
`winrs` tool.

In previous releases, the default port was always 5985, regardless of the
transport being used. To override the default, specify the `winrm_port`
(`-p`) option and specify the desired port as the option's value.

### WinRM authentication protocol defaults to `negotiate` regardless of name formats
Unless explicitly overridden using the new `winrm_authentication_protocol`
option, `knife-windows` subcommands that use WinRM will authenticate using the
negotiate protocol, just as the tools built-in to the Windows operating
system would do.

Previously, `knife-windows` would use basic authentication, unless the
username specified to the `winrm_user` option had the format `domain\user`,
and in that case `knife-windows` would use negotiate authentication.

To override the new behavior, specify the `winrm_authentication_protocol`
option with a value of either the `basic` or `kerberos` to choose a different
authentication protocol.

### New `:winrm_authentication_protocol` option

This option allows the authentication protocol used for WinRM communication to
be explicitly specified. The supported protocol values are `kerberos`, `negotiate`,
and `basic`, each of which directs `knife-windows` to use the respective authentication protocols.

If the option is not specified, `knife-windows` treats this as a default value
of `negotiate` and the tool uses negotiate authentication for WinRM.

### New `:winrm_ssl_verify_mode` option
When running the `winrm` and `bootstrap windows` subcommands with the
`winrm_transport` option set to `ssl` to communicate with a remote Windows system using
the WinRM protocol via the SSL transport, you may disable `knife`'s verification of
the remote system's SSL certificate. This is useful for testing or
troubleshooting SSL connectivity before you've verified the certificate of the remote system's SSL WinRM listener.

The option that controls whether the server is validated is the
`knife[:winrm_verify_ssl_mode]` option, which has the same values as Chef's
[`:ssl_verify_mode`](https://docs.getchef.com/config_rb_client.html#settings) option. By default, the option is set to `:verify_peer`,
which means that SSL communication must be verified using a certificate file
specified by the `:ca_trust_file` option. To avoid the need to have this file available
during testing, you can specify the `knife[:winrm_ssl_verify_mode]` option in
`knife.rb` OR specify it directly on the `knife` command line as
`--winrm-ssl-verify-mode` and set its value to `:verify_none`, which will
override the default behavior and skip the verification of the remote system
-- there is no need to specify the `:ca_trust_file` option in this case.

Here's an example that disables peer verification:

    knife winrm -m 192.168.0.6 -x 'mydomain\myuser' -P "$PASSWORDVAR" -t ssl --winrm-ssl-verify-mode verify_none ipconfig

This option should be used carefully since disabling the verification of the
remote system's certificate can subject knife commands to spoofing attacks.

### New subcommands to automate WinRM SSL listener configuration
The WinRM protocol may be encapsulated by SSL, but the configuration of such
connections can be difficult, particularly when the WinRM client is a
non-Windows system. Three new knife subcommands have been implemented in
knife-windows 1.0.0.rc.0 to simplify and automate this configuration:

* `knife windows cert generate` subcommand:
  Generates certificates in formats useful for creating WinRM SSL listeners.
  It also generates a related public key file in .pem format to validating
  communication involving listeners configured with the generated certificate.
* `knife windows cert install` subcommand:
  Installs a certificate such as one generated by the `cert generate`
  subcommand into the Windows certificate store so that it can be used as the
  SSL certificate for a WinRM listener. This command will only function on the
  Windows operating system. Certificates are always installed in the
  computer's personal store, i.e. the store that can be viewed via the
  PowerShell command `ls Cert:\LocalMachine\My`.
* `knife windows listener create` subcommand:
  Creates a WinRM listener on a Windows system. This command functions only on
  the Windows operating system.

#### Example WinRM listener configuration workflows

The subcommands are used in the following scenarios

##### Creation of a new listener with a new SSL certificate

This workflow assumes that WinRM is enabled on the system, which can be
accomplished with the command

    winrm quickconfig

If you're creating a listener and don't already have an SSL certificate with
which to configure it, you can quickly create an enabled listener with a short
sequence of commands. The example below assumes that the `knife-windows`
plugin is being executed on a Windows system via the PowerShell command shell,
and that the system is registered with the relevant DNS with the name
`mysystem.myorg.org` and that this is the name with which the user would like
to remotely access this system.

This sequence of commands creates a listener -- it assumes the existence of the directory `winrmcerts`
under the user's profile directory:

    knife windows cert generate --domain myorg.org --output-file $env:userprofile/winrmcerts/winrm-ssl
    knife windows listener create --hostname *.myorg.org --cert-install $env:userprofile/winrmcerts/winrm-ssl.pfx

The first command, `cert generate`, may be executed on any computer (even one not running the
Windows operating system) and produces three files. The first two are certificates containing
private keys that should be stored securely. The 3rd is a `.pem` file
containing the public key required to validate the server. This file may be
shared. The command also outputs the thumbprint of the generated certificate,
which is useful for finding the certificate in a certificate store or using
with other commands that require the thumbprint.

The next command, `listener create`,  creates the SSL listener -- if it is executed on a different
system than that which generated the certificates, the required certificate
file **must** be transferred securely to the system on which the listener will
be created. It requires a PKCS12 `.pfx` file for the `--cert-install` argument
which is one of the files generated by the previous `cert generate` command.

After these commands are executed, an SSL listener will be created listening
on TCP port 5986, the default WinRM SSL port. Using PowerShell, the following
command will show this and other listeners on the system:

    ls wsman:\localhost\listener

As an alternative to the command sequence above, the `cert install` command could be used to install the
certificate in a separate step, i which case the `--cert-install` option must
be replaced with the `--cert-thumbprint` option to use the generated
certificate's thumbprint to identify the certificate with which the listener
should be configured:

    knife windows cert generate --domain myorg.org --output-file $env:userprofile/winrmcerts/winrm-ssl 
    knife windows cert install $env:userprofile/winrmcerts/winrm-ssl
    knife windows listener create --hostname *.myorg.org --cert-thumbprint 1F3A70E2601FA1576BC4850ED2D7EF6587076423

The system would then be in the same state as that after the original shorter
command sequence.

Note that the `cert install` command could be skipped if the certificate
already exists in the personal certificate store of the computer. To view that store and
see the thumbprints of certificates that could be used with the `listener
create` command to create an SSL listener, the following PowerShell command
may be executed:

    ls Cert:\LocalMachine\My

##### Connecting to a configured SSL listeners

In order to connect securely to the configured SSL listener via the `knife
winrm` or `knife bootstrap windows winrm` subcommands, the workstation running
`knife` must have a `.pem` file that contains the listener's public key, such
as the one generated by `knife windows cert generate`. If the file was
generated from a different system than the one initiating the connection with
the listener, it must be transferred securely to the initiating system.

For example, assume the file `./winrmcerts/myserver.pem` was securely
copied from another system on which the `cert generate` command originally
produced the file. Now it can be used against a system with the appropriately
configured listener as follows:

    knife winrm -f ./winrmcerts/myserver.pem -m myserver.myorg.com -t ssl ipconfig -x 'my_ad_domain\myuser' -P "$PASSWORDVAR"

This will send the output of the Windows command `ipconfig` on the remote
system. The argument to the `-f` option is the public key for the listener so
that the listener's authenticity can be validated. The specified key
can simply be a copy of the `.pem` file generated by the `cert generate` subcommand if
that was used to create the certificates for the listener. The user
`my_ad_domain\myuser` in the example is a user in the Windows Active Directory
domain `my_ad_domain`.

Alternatively, the [`knife ssl fetch`](https://docs.chef.io/knife_ssl_fetch.html) command can be used to retrieve the
public key for the listener by simply reading it from the listener, though this command *must* be executed under
conditions where the connection to the server is considered secure:

     knife ssl fetch https://myserver.myorg.org:5986/wsman
     knife winrm -f ./.chef/trusted_certs/wildcard_myorg_org.crt -m myserver.myorg.com -t ssl ipconfig -x 'my_ad_domain\myuser' -P "$PASSWORDVAR"

In the `fetch` subcommand, the URL specified for testing WinRM connectivity to
a given server SERVER on port PORT takes the form `https://SERVER:PORT/wsman`,
hence the url specified above to retrieve the key for `myserver.myorg.org`.
The command also outputs the location to which the key was retrieved, which
can then be used as input to a subsequent `knife winrm` command.

For that `knife winrm` command in the example, the argument to the `-f` option is again the public key -- this time its value
of `./.chef/trusted_certs/wildcard_myorg_org.crt` is the file system location to which
`knife ssl fetch` retrieved the public key.

#### Testing WinRM SSL configuration

The techniques below are useful for validating a WinRM listener's configuration -- all
examples below assume there is a WinRM SSL listener configured on a remote Windows
system `winserver.myoffice.com` on the default WinRM port of 5986 and this is
the server being tested.

##### PowerShell's `test-wsman` cmdlet
If you have access to a workstation running
the Windows 8 or Windows Server 2012 or later versions of the Windows
operating systems, you can use the `test-wsman` command to validate the
configuration of a listener on a remote system `winserver.myoffice.com`:

1. On the Windows workstation client (not the system with the listener),
    install the .pfx public key certificate for the listener using
    certmgr.msc. This should be installed in the personal store under *"Trusted
    Root Certification Authorities"*.
2. Start PowerShell, and use it to run this command:
    `test-wsman -ComputerName winserver.myoffice.com -UseSSL`

If the command executes without error, the ssl configuration is correct.

##### End to end SSL testing with `knife winrm`

To validate that SSL is enabled for the listener without validating the
server's certificate, the `--winrm-ssl-verify-mode` option of the `winrm`
subcommand can be used:

     knife winrm -m winserver.myoffice.com -t ssl --winrm-ssl-verify-mode verify_none ipconfig -x 'my_ad_domain\myuser' -P "$PASSWORDVAR"

If this succeeds, then any failures to execute the command when correctly
validating the server, i.e. when specifying the `-f` parameter, are due to
certificate configuration issues, not other connectivity or authentication
problems.

##### The winrs tool

The `winrs` tool is built into Windows, so if a Windows system is available,
`winrs` may be used to troubleshoot. It takes parameters analogous to those of
`knife winrm` and differences in success and failure between the two tools may
indicate areas to investigate.

Visit Microsoft's documentation for [`winrs`](https://technet.microsoft.com/en-us/library/hh875630.aspx) to learn more about the tool.

### Troubleshooting WinRM authentication issues

Authentication issues can be debugged by loosening the authentication
requirements on the server and explicitly using
`--winrm-authentication-protocol` option for `knife winrm` to attempt to
connect. As an example, the following PowerShell commands on the server will allow basic authentication
and unencrypted communication:

    si wsman:\localhost\service\allowunencrypted $true
    # Don't set the following if attempting domain authentication
    si wsman:\localhost\service\auth\basic $true

From the client, `knife winrm` can be instructed to explicitly allow basic
authentication when validating authentication using a non-domain (i.e. local)
account:

    # For testing a local account
    knife winrm -m winserver.myoffice.com --winrm-authentication-protocol basic ipconfig -x 'localuser' -P "$PASSWORDVAR" -VV

    # For testing a domain account
    knife winrm -m winserver.myoffice.com --winrm-authentication-protocol negotiate ipconfig -x 'localuser' -P "$PASSWORDVAR" -VV

If the listener is an SSL listener, the additional arguments `-t ssl
--winrm-ssl-verify-mode verify_none` should be supplied to enable SSL
communication and disable peer verification for testing. The specification of
`-VV` enables additional detailed debug output that can provide clues to the
root cause of any failures.

If the command fails, there is either a connectivity issue or a problem with
an incorrect or expired password or disabled account.

If the command succeeds, try the following

    si wsman:\localhost\service\allowunencrypted $false

Then retry the earlier `knife winrm` command. If it fails, this may indicate
an issue with your operating system's ability to encrypt traffic, particularly
when using the `plaintext` transport, i.e. when not using the `SSL` transport.
In that case, the Windows platform supports encryption of plaintext traffic
through native Windows authentication protocols, but such support is often incomplete on other platforms.

If the command succeeds, then there may be a more subtle issue with negotiate
authentication. It may be necessary to explicitly specify a domain in the user
name parameter (e.g. `mydomain\myuser` rather than just `user`) for instance,
or a specified domain may actually be incorrect and something that should be omitted.

### Platform WinRM authentication support

`knife-windows` supports `Kerberos`, `Negotiate`, and `Basic` authentication
for WinRM communication. However, some of these protocols
may not work with `knife-windows` on non-Windows systems because
`knife-windows` relies on operating system libraries such as GSSAPI to implement
Windows authentication, and some versions of these libraries do not
fully implement the protocols.

The following table shows the authentication protocols that can be used with
`knife-windows` depending on whether the knife workstation is a Windows
system, the transport, and whether or not the target user is a domain user or
local to the target Windows system.

| Workstation OS / Account Scope | SSL                          | Plaintext                  |
|--------------------------------|------------------------------|----------------------------|
| Windows / Local                | Kerberos, Negotiate* , Basic | Kerberos, Negotiate, Basic |
| Windows / Domain               | Kerberos, Negotiate          | Kerberos, Negotiate        |
| Non-Windows / Local            | Kerberos, [Negotiate*](https://github.com/chef/knife-windows/issues/176) Basic | Kerberos, Basic |
| Non-Windows / Domain           | Kerberos, Negotiate          | Kerberos                   |

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
> a domain account instead, or enabling Basic authentication on the remote
> system (unencrypted communication **does not** need to be enabled to make
> Basic authentication function over SSL).
