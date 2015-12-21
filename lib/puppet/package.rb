require 'puppet/indirector'
require 'puppet/face'

class Puppet::Package

  # Set up indirection
  extend Puppet::Indirector

  indirects :package, :terminus_setting => :package_terminus

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
    packages = system_packages
    package_updates = Hash.new

    prefetch_updates(packages)

    packages.each do |p|
      provider = String(p[:provider])

      unless package_updates[provider]
        package_updates[provider] = Hash.new
      end

      # Some providers can't determine latest versions
      next unless p.provider.class.method_defined?(:latest)

      # Need to access with Array because sometimes puppet hands back
      # strings, sometimes it hands back arrays containing a string. Oy.
      # Using confusing [*] syntax for speed.
      latest  = [*p.provider.latest][0]
      current = [*p.provider.properties[:ensure]][0]

      # filter out packages that apt reports as "installed" but not "purged"
      # as well as packages with no upgrade
      next unless latest && (current != "absent")

      if latest != current
        package_updates[p.title] = {
          'current'  => current,
          'update'   => latest,
          'provider' => String(p[:provider])
        }
      end
    end

    {'package_updates' => package_updates }
  end

  private
  
  # Some providers require prefetching, while others don't even implement it
  # This method collects all of the providers for a given set of packages,
  # then calls prefetch on those that implement a prefetch method.
  def prefetch_updates(packages)
    providers = packages.map {|p| p.provider.class }.uniq
  
    providers.each do |provider|
      next unless provider.methods.include? "prefetch"
      to_prefetch = packages.select { |p| p.provider.class == provider }
  
      # We have to submit packages to prefetch methods in title-keyed hash
      prefetch_hash = Hash.new
      to_prefetch.each { |p| prefetch_hash[p.title] = p }
  
      # At least one package must be ensure => latest, or else lazy loading
      # mechanisms will "helpfully" prevent prefetching
      prefetch_hash[prefetch_hash.keys.first][:ensure] = :latest
  
      provider.prefetch(prefetch_hash)
    end
  end
end
