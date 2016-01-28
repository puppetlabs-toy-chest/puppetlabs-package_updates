require 'puppet/node'
require 'puppet/node/patches'
require 'puppet/resource/catalog'
require 'puppet/indirector/catalog/compiler'

# Implement a skeleton for a compiler catalog terminus that adds package patch resources
class Puppet::Resource::Catalog::PackageUpdates < Puppet::Resource::Catalog::Compiler

  def find(request)
    catalog = super(request)
    node = node_from_request(request)

    Puppet.notice "Adding patches for #{node.name} to catalog"

    managed_packages = catalog.resources.find_all { |resource| resource.type == 'Package' }

    package_updates = Array.new
    retrieve_package_updates(node).each do |name,parameters|
      package_parameters = { :name => name,
        :ensure   => parameters['version'],
        :provider => parameters['provider']
      }

      package_updates << create_package_object(name, package_parameters)
    end

    package_updates.each do |package_update|
      if catalog_package = managed_packages.find { |r|
          r[:name] == package_update[:name] and r[:provider] == package_update[:provider]
        }
        # Make sure not to override the version if the version is managed by Puppet code
        if [nil,'installed','present','absent','purged'].include? catalog_package[:ensure]
          catalog_package[:ensure] = package_update[:ensure]
        else
          # If we're here, the version is being specified in Puppet code
          unless catalog_package[:ensure] == package_update[:ensure]
            # The specified update doesn't match what's specified in Puppet code
            Puppet.warn "Not overriding version #{catalog_package[:ensure]} with specified update #{package_update[:ensure]} for package #{package_update[:name]}"
          end
        end
      else
        catalog.add_resource package_update
      end
    end

    catalog
  end

  private

  def create_package_object(title, parameters)
    Puppet::Resource.new(Puppet::Type::Package, title, {:parameters => parameters})
  end

  def retrieve_package_updates(node)
    begin
      Puppet::Node::Patches.find(node)
    rescue Puppet::Node::Patches::NoPatchFile => e
      Puppet.warning e
      Puppet.warning "Continuing with compilation without managing patches"
      return Hash.new
    end
  end
end
