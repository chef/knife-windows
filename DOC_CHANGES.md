<!---
This file is reset every time a new release is done. This file describes changes that have not yet been released.

Example Doc Change:
### Headline for the required change
Description of the required change.
-->

# knife-windows 0.8.0 doc changes

### Negotiate / NTLM authentication support
If `knife` is executed from a Windows system, it is no longer necessary to make
additional configuration of the WinRM listener on the remote node to enable
successful authentication from the workstation. It is sufficient to have a WinRM
listener on the remote node configured according to the operating system's `winrm
quickconfig` command default configuration because `knife-windows` now
supports the Windows negotiate protocol including NTLM authentication, which
matches the authentication requirements for the default WinRM listener configuration.

If `knife` is executed on a non-Windows system, certificate authentication or Kerberos
should be used instead via the `kerberos_service` and related options of the subcommands. 

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


