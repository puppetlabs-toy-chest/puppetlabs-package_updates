require 'puppet/node'
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
    retrieve_package_updates.each do |name,parameters|
      package_parameters = { :name => name,
        :ensure   => parameters['update'],
        :provider => parameters['provider']
      }

      package_updates << create_package_object(name, package_parameters)
    end

    package_updates.each do |package_update|
      if catalog_package = managed_packages.find { |r|
          r[:name] == package_update[:name] and r[:provider] == package_update[:provider]
        }
        catalog_package[:ensure] = catalog_update[:ensure]
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

  def retrieve_package_updates
    {"grub2" => {"current" => "7:2.02.105-14.el7", "update" => "1:2.02-0.34.el7.centos","provider" => "yum"}}
  end
end
