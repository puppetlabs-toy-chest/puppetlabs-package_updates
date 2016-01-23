# package_updates

#### Table of Contents

1. [Module Description - What the module does and why it is useful](#module-description)
2. [Setup - The basics of getting started with package_updates](#setup)
    * [What package_updates affects](#what-package_updates-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with package_updates](#beginning-with-package_updates)
3. [Usage - Configuration options and additional functionality](#usage)
4. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)

## Module Description

This is a proof-of-concept module  that provides a [Puppet Face](https://puppetlabs.com/puppet-faces-faq) to
query available package updates from all package providers available on the system. The
Face is able to query from over 12 package managers out of the box and more can be added by
downloading modules from the Forge that include additional package providers, such as the
[chocolatey/chocolatey](https://forge.puppetlabs.com/chocolatey/chocolatey) module for Windows.

In addition to the Puppet Face, the module provides a class that manages a cron job to scan
for available package updates on a regular schedule.  The cron job takes the output and generates
a custom Facter fact so the package update status is always up to date in PuppetDB.  Keeping the
data in PuppetDB provides an easy interface to query for available updates and generate
custom reports.

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
