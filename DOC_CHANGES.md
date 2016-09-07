<!---
This file is reset every time a new release is done. This file describes changes that have not yet been released.

Example Doc Change:
### Headline for the required change
Description of the required change.
-->
# knife-windows 1.6.0 doc changes

### Choosing a winrm shell

<!---
This file is reset every time a new release is done. The contents of this file are for the currently unreleased version.

Example Note:

## Example Heading
Details about the thing that changed that needs to get included in the Release Notes in markdown.
-->
# knife-windows 1.6.0 release notes:

This release adds a `--winrm-shell` argument to `knife winrm`. This accepts one of three possible values: `cmd`, `powershell` or `elevated`. The default value is `cmd`. The `elevated` shell is similar to the `powershell` shell but runs the powershell command from a scheduled task.
