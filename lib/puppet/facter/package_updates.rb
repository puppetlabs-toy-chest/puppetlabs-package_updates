require 'puppet'

Facter.add('package_updates') do
  system_packages = Puppet::Type.type(:package).instances

  setcode do
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

    providers = Hash.new
    package_updates.each do |package,info| 
      provider = info['provider']

      unless providers[provider]
        providers[provider] = 0
      end

      providers[provider] += 1
    end

    {'packages' => package_updates, 'providers' => providers }
  end
end

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
