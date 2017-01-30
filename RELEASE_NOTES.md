<!---
This file is reset every time a new release is done. The contents of this file are for the currently unreleased version.

Example Note:

## Example Heading
Details about the thing that changed that needs to get included in the Release Notes in markdown.
-->
# knife-windows 1.9.0 release notes:

This release re-introduces support for concurrent WinRM connections when
running `knife winrm`. Simply specify the number of concurrent connections
you would like using the `-C` (or `--concurrency`) flag.

```
knife winrm "role:web" "net stats srv" -X Administrator -P 'super_secret_password' -C 4
```
