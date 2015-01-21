<!---
This file is reset every time a new release is done. This file describes changes that have not yet been released.

Example Doc Change:
### Headline for the required change
Description of the required change.
-->
# knife-windows 0.10.0 doc changes

### New `:winrm_ssl_verify_mode` option
When running the `winrm` and `bootstrap windows` subcommands with the
`:winrm_transport` option set to `ssl` to communicate with a remote Windows system using
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

    knife winrm -m 192.168.0.6 -x 'mydomain\myuser' -P $PASSWORDVAR -t ssl
    --winrm-ssl-verify-mode verify_none -p 5986 ipconfig 

This option should be used carefully since disabling the verification of the
remote system's certificate can subject knife commands to spoofing attacks.
