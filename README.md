# package_updates

#### Table of Contents

1. [Module Description](#module-description)
2. [Setup](#setup)
    * [What package_updates affects](#what-package_updates-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with package_updates](#beginning-with-package_updates)
3. [Usage](#usage)
    * [Setting up a scan schedule](#setting-a-scan-schedule)
    * [Using the custom fact](#using-the-custom-fact)
    * [Querying infrastructure patch state](#querying-infrastructure-patch-state)
    * [Patch deployment](#patch-deployment)
4. [Reference](#reference)
5. [Limitations - OS and Puppet compatibility](#limitations)

## Module Description

This is an experimental module that aims to enable continuous delivery of all
package updates within an infrastructure across any package manager that has a
Puppet provider that supports the upgradeable feature. Package information is
stored in PuppetDB is inventory information and package update versions are
specified in Hiera as part of a r10k change management process.

The module provides a [Puppet Face](https://puppetlabs.com/puppet-faces-faq) to
query available package updates from all package providers available on the system. The
Face is able to query from over 12 package managers out of the box and more can be added by
downloading modules from the Forge that include additional package providers, such as the
[chocolatey/chocolatey](https://forge.puppetlabs.com/chocolatey/chocolatey) module for Windows.

The provided **package_updates** class manages a cron job to scan the system
for available package updates on a regular schedule.  The cron job takes the
output from the included `puppet package updates` plugin and generates a
custom Facter fact so the package update status is always up to date in
PuppetDB.  Keeping the data in PuppetDB provides an easy interface to query
for available updates and generate custom reports.

This module also includes a catalog terminus that searches for package update
information in Hiera, and injects that information into a normally compiled
catalog.  This way, package updates can be managed regularly as package
resources in Puppet code, while the updates to those packages, and all packages
NOT managed by Puppet, can be managed as Puppet resources.  Updates are
continuously enforced each Puppet run, show up in the Puppet reports, and are
fully auditable.


## Setup

### What package_updates affects

* A cron job in the root user's crontab
* A custom Facter fact with package update information

### Setup requirements

* Add the package_updates class to all node groups you want to monitor updates on

### Beginning with package_updates

To have nodes scan for updates on a regular cadence and report the result as a custom fact,
declare the ***package_updates*** class to any node or node group you'd like to monitor for updates.

### Usage

#### Setting a scan schedule

The module contains a single class: **package_updates**.  This class sets up a
cron job to run the puppet face and caches the result in an external fact.  By
default, the cron job runs every day at 3:00am.  You can change that with the
available class parameters.

* minute - The minute at which to run the scan. Default: undef
* hour - The hour at which to run the scan. Default: 3
* month - The month of the year. Default: undef
* monthday - The day of the month to run the scan. Default: undef
* weekday - The day of th week to run the scan. Default: undef

#### Using the Puppet Command Line Interface

After installing the module on the Puppet master, each Puppet agent will pluginsync the libraries
to their local file systems.  Once the sync happens, you can use the following command to get a list of
all the packages that have updates available.

    $ puppet package updates

You can also request the output be in JSON serialized format

    $ puppet package updates --render-as json

#### Using the custom fact

The available package updates on the system can be retrieved as a structured custom fact.  Since it
can take several seconds to scan the system for updates, it's preferable to scan for updates at a
regular cadence and cache the results for Facter to retrieve.

The package_updates class provides a way to set a schedule for the system to scan for package updates
and caches the results for Facter.

#### Querying infrastructure patch state

You can use PuppetDB's API to query the patch state for different parts of the infrastructure.
For example, to query for all production systems that have updates available, the following query can
be used against the /pdb/query/v4/facts endpoint:

    ["and",
      ["=", "name", "package_updates"],
      ["=", "environment", "production"]
    ]

The following query will retrieve all updates for packages that's version is not being managed by Puppet

    ["and",
      ["=", "environment", "production"],
      ["in", "name",
        ["extract", "name",
          ["select-resources",
            ["and",
              ["=", "type", "package"],
              ["not",
                ["or",
                  ["=", "ensure", "latest"],
                  ["~", "ensure", "^(?:(\d+)\.)?(?:(\d+)\.)?(\*|\d+)$"]
                ]
              ]
            ]
          ]
        ]
      ]
    ]

You can use [subqueries](https://docs.puppetlabs.com/puppetdb/3.2/api/query/v4/facts.html#subquery-relationships) to construct more targeted queries.


#### Patch deployment

This module provides a catalog terminus called **package_updates**.  The
catalog terminus injects patch information into a node's commpiled catalog. To
set the terminus, set the **catalog_terminus ** setting in the **master**
section of the /etc/puppetlabs/puppet/puppet.conf file to the value of
**package_updates** by running the folllowing comand.  Restart the puppetserver
service once complete.

    puppet config set catalog_terminus package_updates

For Puppet Enterprise installations, simply declare the
**package_updates::pe_master** class in the **PE Master** node group in the
Puppet Enterprise Console.


To apply patches to systems, a hash of package versions to be applied must be
generated and added to your r10k control repository. By specifying patch
information in the control repo, patches can be defined, tested, and promoted
through the delivery process you already use for all other code.

The hash follows the following example yaml format:

    package_updates:
      classes:
        role::webserver
          apache:
            version: '2.9.3.el7'
            provider: 'yum'
      gcc:
        version: '4.8.5-4.el7'
        provider: 'yum'

The **classes** key in the package_updates hash contains a hash where each key
is the name of a Puppet class that should have the patches specified applied to
any system with that class. Any packages specified outside the **classes** key
are assumed global and will apply to any system at all.

**Using Hiera**

The default terminus for retrieving patches is from Hiera.  Hiera enables users
to break the package_updates hash into hierarchies such as patch information
for Red Hat systems vs Ubuntu or specifying patches assigned to geographical location.

The Puppet::Node::Patches indirector finds all instances of the package_updates
hash in any hierarchy that applies to the node, merging all found instances of
package_updates.

#### Report Generation

Since the PuppetDB query outputs standard JSON, existing tools can be used to generate spreadsheet
reports or custom interfaces can be built that renders the serialized data.

Suggested tools:

  * Ruby - [json2csv](https://github.com/ngmaloney/json2csv)
  * NodJS - [json2csv](https://github.com/zemirco/json2csv)


### Limitations

This module is compatible with Puppet 4.x+ only. It makes use of the Puppet 4 parameter data type
validation which is incompatible with Puppet 3.x

This tool currently only works with non-Windows systems. Once the interface can handle both cron
and scheduled_task resources, Windows support for package management systems like Chocolatey
can easily be added.
