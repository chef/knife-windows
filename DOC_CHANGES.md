<!---
This file is reset every time a new release is done. This file describes changes that have not yet been released.

Example Doc Change:
### Headline for the required change
Description of the required change.
-->

# knife-windows 0.8.2 doc changes

### Negotiate / NTLM authentication support
If you are running `knife-windows` subcommands from a Windows workstation, you
should not specify a username argument that includes a domain name (i.e. a
name formatted like `domain\user`) unless the remote host has WinRM's
`AllowUnencrypted` setting set to `$false` (the default setting on Windows if
the `winrm quickconfig` command was used to enable WinRM). If you've modified
the host to set this to `$true` instead of its default value and you run
subcommands from a Windows workstation where the username specified to
`knife-windows` contains a domain, the command will fail with an
authentication error. To avoid this, omit the domain name (this will only work
if the system is not joined to a domain, i.e. you were specifying the local
workstation as the domain), or set `AllowUnencrypted` to `$false` which is a
more secure setting.
