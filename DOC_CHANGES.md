<!---
This file is reset every time a new release is done. This file describes changes that have not yet been released.

Example Doc Change:
### Headline for the required change
Description of the required change.
-->
# knife-windows 1.2.0 doc changes

### Support for NTLM/Negotiate on both windows and linux

This release makes no changes to the command line interface, but users should now be aware that Negotiate authentication and encryption over plaintext HTTP now works on linux in addition to windows.

Users who use knife-windows to bootstrap nodes over plaintext HTTP should also be aware that they no longer need, and in fact should not, configure base images enabling `basic_auth` or enabling `AllowUnencrypted` in their winrm configuration.
