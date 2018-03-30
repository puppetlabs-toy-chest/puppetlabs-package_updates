require 'puppet/indirector/face'
require 'puppet/package'

Puppet::Indirector::Face.define(:package, '0.0.1') do
  copyright "Puppet Labs", 2011
  license   "Apache 2 license; see COPYING"

  summary "View and manage packages on a node."
  description <<-'EOT'
    This subcommand interacts with package objects, using the default provider.
    Upgrading multiple packages and viewing what updates are available for any
    package type requires providers  that supports 'versionable' and 'upgradeable'.
  EOT

  save = get_action(:save).summary "Invalid for this face. Use the resource subcommand"
  destroy = get_action(:destroy).summary "Invalid for this face. Use the resource subcommand"

  action :updates do
    summary "List all packages with updates available from packaging system"
    returns <<-'EOT'
    A hash where the key is the package and the value is a hash containing `update`,
    `current`, and `provider`
    EOT

    when_invoked do  |options|
      #We don't want the catalog.apply to print the logs to stdout
      Puppet::Util::Log.close_all

      Puppet::Package.find_updates
    end

    when_rendering :console do |package_updates|
      packages = package_updates['package_updates']
      output = Array.new

      #Provide pretty output
      layout = "\033[31m%-40s\033[32m%-30s\033[0m      \033[32m%-30s\033[0m%s"

      output << layout % ["PACKAGE NAME", "CURRENT VERSION", "UPDATE AVAILABLE", "PROVIDER"]
      output << '-'*120

      output << packages.map do |name,package|
        layout % [name, package['current'], package['update'], package['provider'] ]
      end

      output.flatten.join("\n")
    end

    when_rendering :json do |package_updates|
      package_updates.to_json
    end
  end

  action :update do
    summary "Perform an update on a package"
    arguments "<package_name> | <package hash>"
    examples <<-EOT
      When invoked from the command line:

      $ puppet package update apr [--provider rpm] [--level 1.2.7-11.el5_6.5]

      Or you can use in API form by passing in a hash of packages where each package value
      contains a hash with keys `update` and `provider`:

      updates = {
        'apr'   => { :update => '1.2.7-11.el5_6.5', :provider => :rpm }
        'stomp' => { :update => '1.1.6', :provider => :gem }
      }

      Puppet::Face[:package, '0.0.1'].update updates
    EOT

    Puppet::Package.add_update_options(self)

    when_invoked do |package, options|
      if package.class == Hash
        Puppet::Package.apply_updates package
      elsif package.class == String
        Puppet::Package.update_package(package, options)
      else
        raise "Must give a Hash for String to update action"
      end
      nil #Don't render anything
    end
  end

  action :list do
    default
    summary "List installed packages"

    when_invoked do |options|
      Puppet::Package.system_packages
    end

    when_rendering :console do |packages|
      packages.map do |package|
        package.name
      end.join("\n")
    end
  end
end
