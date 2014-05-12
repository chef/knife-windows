<!---
This file is reset every time a new release is done. This file describes changes that have not yet been released.

Example Doc Change:
### Headline for the required change
Description of the required change.
-->

# knife-windows 0.6.0 doc changes:

### `--auth-timeout` option for bootstrap
The `knife windows bootstrap` command has a new `--auth-timeout` option that
takes a number of minutes as an argument. After the command has detected that
the node to be bootstrapped has opened a port for the desired transport (e.g.
WinRM), the command then tries to successfully execute a remote test command
on the system to verify authentication and will retry for the number of minutes specified in the
`--auth-timeout` option if an authentication error is received. This is
particularly useful for nodes hosted by cloud providers that may open up ports before user
identities that can be authenticated are configured on the system, or if the
authentication subsystem's readiness lags that of transport readiness.

If the `--auth-timeout` option is not specified, the default retry period is
25 minutes.

This value is currently only honored when bootstrapping using the WinRM
transport and is ignored when bootstrapping via ssh.

### New configuration option for `knife winrm`: `:suppress_auth_failure`
The option `:suppress_auth_failure` may be configured in `knife.rb` to alter
the behavior of the `knife winrm` subcommand's behavior when authentication
fails:

* When this option is not specified (the default case) or is configured as `false`, the `knife winrm`
subcommand will return a process exit code of `100` if the command is able to
connect to the WinRM transport on the remote system but fails to authenticate.
* When this option is set to `true`, the exit status in the authentication
failure case is `0`. 

The default behavior is retained for compatibility reasons. The ability to
override it via the `:suppress_auth_failure` option is useful for automation that uses the `knife winrm` subcommand
and needs to implement customized retry behavior when authentication fails.

