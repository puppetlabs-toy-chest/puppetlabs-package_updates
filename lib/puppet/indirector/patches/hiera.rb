require 'puppet/indirector'
require 'puppet/indirector/hiera'
require 'puppet/node/patches'

class Puppet::Node::Patches::Hiera < Puppet::Indirector::Hiera
  desc "Retrieve patch state from Hiera."

  def find(request)
    node = request.key

    all_patches = hiera.lookup('package_updates', {}, node.parameters, {}, convert_merge('deep'))

    patches_to_be_applied = Hash.new

    classes_with_patches = node.classes.select { |c| all_patches.has_key?(c) }
    classes_with_patches.each do |klass|
      role = klass.first
      patches_to_be_applied.merge! all_patches[role]
    end

    patches_to_be_applied
    
  rescue *DataBindingExceptions => detail
    error = Puppet::DataBinding::LookupError.new("DataBinding 'hiera': #{detail.message}")
    error.set_backtrace(detail.backtrace)
    raise error
  end
end
