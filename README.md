Description
===========

This module provides a custom fact that returns all packages that have updates
available.  It works will all package providers on the system that support
**upgradeable**

Retrieving
----------

The fact values are available in PuppetDB. Using the PuppetDB v4 API, queries can be used to ask questions about the updates available. 
The Following examples show queries against the v4 /fact-contents PuppetDB endpoint.

All updates available for the apt provider:
```
["and", ["=", "value", "apt"], ["~>", "path", [ "package_updates", "packages", ".*", "provider" ]]]
```

To find all updates available for RPM in the production environment:
```
["and", ["=", "value", "apt"], ["~>", "path", [ "package_updates", "packages", ".*", "provider" ]], ["=", "environment", "production"]]
```

All updates available in production that's version is not being managed by Puppet:
```
["and", ["=", "environment", "production"], ["in", "name", ["extract", "name", ["select-resources", ["and", ["=", "type", "package"], ["not", ["or", ["=", "ensure", "latest"], ["~", "ensure", "^(?:(\d+)\.)?(?:(\d+)\.)?(\*|\d+)$"]]]]]]]]
```
