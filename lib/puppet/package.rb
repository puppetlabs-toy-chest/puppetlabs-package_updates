require 'puppet/indirector'
require 'puppet/face'

class Puppet::Package

  # Set up indirection
  extend Puppet::Indirector

  indirects :package, :terminus_setting => :package_terminus

  #Set our default indirector
  # Am I doing this right?
  Puppet.setdefaults(:main, :package_terminus => ["plain",'Where to get package information'])

  def self.[](name)
    system_packages.each do |package|
      if package.name == name
        return package
      end
    end
  end

  def self.add_update_options(action)
    action.option '--level=', '-l=' do
      summary "The version level to patch to. Default is latest"
    end

    action.option '--provider=', '-p=' do
      summary "The provider for the package. Defaults to system default provider"
    end
  end

  def self.system_packages
    #Can't use Puppet::Resource face here
    #Since it doesn't return package objects
    Puppet::Type.type(:package).instances
  end

  #Takes in an array of Puppet::P
  def self.apply_catalog(packages)
    catalog = Puppet::Resource::Catalog.new

    #According to the resources/catalog.rb file, you
    #should be able to pass an array of resources
    #to add_resource, but you can't, hmmm
    packages.each do |package|
      catalog.add_resource package
    end

    catalog.apply
  end

  #Takes a hash in the form
  #  package_name = {
  #    :update => <update_version>
  #    :provider => <provider>
  #  }
  def self.apply_updates(packages)
    packages.each do |name, package|
      unless system_packages.map{ |p| p.name }.include? name
        raise "#{name} is not installed on the system"
      end

      package_resource = Puppet::Resource.new( :package, "Package[#{name}]",
        :parameters => {:ensure => package[:update], :provider => package[:provider]}
      )

      #Apply the update
      begin
        Puppet::Face[:resource,'0.0.1'].save package_resource
      rescue => e
        raise "Could not update \033[31m#{name}\033[0m: #{e}"
      end
    end
  end

  def self.update_package(package, options)
    #The other methods expect the package name to be in the following format
    level    = options.has_key?(:level) ? options[:level] : :latest
    provider = options.has_key?(:provider) ? options[:provider] : Puppet::Type.type(:package).defaultprovider.name

    #unless system_packages.map{ |p| p.name }.include? package
      #raise ArgumentError, "#{package} is not installed on the system"
    #end

    #Perform the update
    apply_updates package => { :update => level, :provider => provider }
  end

  def self.find_updates
    package_updates = Hash.new

    #Get our system packages, change our desired ensure to :latest
    # and set it not to change anything when we apply the catalog
    catalog_packages = system_packages.map do |package|
      package[:ensure] = :latest
      package[:noop]   = true

      #The events in the reports from executing our manual built
      #catalog won't give us the provider, so we need to save it now
      package_updates[package.name] = {
        :provider => package[:provider]
      }

      package #We need our array to contain the actual package objects
    end

    #Filter out packages which providers don't support upgradeable
    ## Why won't select! work here?
    catalog_packages.reject! { |package|  ! package.provider.upgradeable? }

    report = apply_catalog(catalog_packages)
    report.events.each do |update|
      resource = update.instance_variable_get('@resource').split('[').last.chop

      #The event doesn't show what the update version is
      # so we have to extract it from the message
      current_version = update.previous_value
      update_version = update.message.split(',')[-1]
      update_version  = update_version.split[2] # (noop) is the last element & some providers have bugs that report spaces in versions

      package_updates[resource][:current]  = current_version
      package_updates[resource][:update]   = update_version
    end

    #Filter only the packages we found updates for
    #Also, filter out packages that apt reports as "installed", but not "purged"
    package_updates.reject{ |p,h| (! h.has_key?(:update)) or h[:current] == 'absent' }
  end
end
