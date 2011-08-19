require 'puppet/package'
require 'puppet/indirector/plain'

class Puppet::Package::Plain < Puppet::Indirector::Plain
  desc "Query all available pacakge providers that support `upgradeable` and `versionable`
  for package instances."

  def find(request)
      Puppet::Package[request.key]
  end

  def destroy(request)
    #I want to return a report, so I can't use the resource Face
    catalog = Puppet::Resource::Catalog.new

    package = Puppet::Face[:package, '0.0.1'].find(request.key)
    package[:ensure] = :absent

    catalog.add_resource package

    catalog.apply #Returns a report
  end
end
