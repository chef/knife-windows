<!---
This file is reset every time a new release is done. The contents of this file are for the currently unreleased version.

Example Note:

## Example Heading
Details about the thing that changed that needs to get included in the Release Notes in markdown.
-->
# knife-windows 1.8.0 release notes:

This release allows user to specify `config_log_location` and `config_log_level` options in config.rb/knife.rb. This sets the default `log_location` and `log_level` in the `client.rb` file of the node being bootstrapped.

This is how you can pass the values in config.rb/knife.rb:
```
chef_log_level  :debug
chef_log_location "C:/chef.log"    #please make sure that the path exists
```
