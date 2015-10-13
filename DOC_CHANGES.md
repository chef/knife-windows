<!---
This file is reset every time a new release is done. This file describes changes that have not yet been released.

Example Doc Change:
### Headline for the required change
Description of the required change.
-->
# knife-windows 1.1.0 doc changes

### Support for `http_proxy` setting for `winrm` and `bootstrap windows winrm` subcommands

Both the `knife winrm` and `knife bootstrap windows winrm` subcommands
will honor the `http_proxy` configuration in the `knife.rb`
configuration file.

When this setting is configured, the `WinRM` traffic between the
workstation executing `knife` and the remote node will flow through
the proxy server configured with `http_proxy`. See the specific
documentation for `http_proxy` for additional details.

