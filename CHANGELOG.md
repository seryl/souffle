# Changelog

### v0.0.5

* Added chef-server/chef-client orchestration
* Fixed mdadm creation issues
* Fixed merging for system attributes

### v0.0.4

* Added chef-client support
* Added warning for cli one-off runs
* Added provider plugins support
* Added provider helper methods
* Updated documentation
* System timeout set to 10 minutes
* Updated handler for node provisioning
* Updated handler for system provisioning
* Node provisioning updates are now evented
* Updated eventmachine to 1.0.0
* Fixed timing issue with mdadm install

### v0.0.3

* Multiple documentation updates
* AWS provider
  * Tags now use `hex(4)` instead of `hex(6)`
  * Deprecated default tag prefix
* Added chef roles support to providers
* Fixed /version url link
* Added `tag`, `domain`, and `fqdn` node helpers
* Bugfix for repo_path
* Hostname is now set at provisioning

### v0.0.2

* AWS provider
  * Added EBS support
  * Added RAID support
  * Added LVM Support
* Added support for chef-solo provisioning
* Switched from `Puma` to `Thin`
* Updated REST API
* Updated command line interface
* Initial Documentation
* Optimized AWS polling mechanism
* Optimized AWS creation ordering

###  v0.0.1

* Application framework laid out
* Initial node state machine
* Initial system state machine
* Added AWS provider
* Initial command line interface
* Added daemonization
* Added singleton configuration
* Initial runlist parser
* Initial dependency traversal
* System rebalancing (pre-provisioning)
* Added REST API
