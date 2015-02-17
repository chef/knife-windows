<!---
This file is reset every time a new release is done. The contents of this file are for the currently unreleased version.

Example Note:

## Example Heading
Details about the thing that changed that needs to get included in the Release Notes in markdown.
-->
# knife-windows 0.8.4 release notes
This release of knife-windows addresses the lack of a way to configure the ssl settings
of a client when bootstrapped. knife-windows now mimics 'knife bootstrap' such that
new systems will have the trusted_certs_dir that is specified on the workstation copied
to the new node. Additional SSL related settings including verify_api_cert and
ssl_verify_mode will be set in the bootstrapped nodes client.rb to match the settings
in the workstations knife.rb.

## Features added in knife-windows 0.8.4
None.

## Issues fixed in knife-windows 0.8.4
[knife-windows #133](https://github.com/opscode/knife-windows/issues/133) Bootstrap failure -- unable to validate SSL chef server endpoints

## knife-windows on RubyGems and Github
https://rubygems.org/gems/knife-windows
https://github.com/chef/knife-windows

