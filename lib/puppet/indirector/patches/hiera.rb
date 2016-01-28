require 'puppet/indirector'
require 'puppet/indirector/hiera'
require 'puppet/node/patches'

class Puppet::Node::Patches::Hiera < Puppet::Indirector::Hiera
  desc "Retrieve patch state from Hiera."

  def find(request)
    node = request.key

    hiera.lookup('package_updates', {}, node.parameters, {}, convert_merge('deep'))
    
  rescue *DataBindingExceptions => detail
    error = Puppet::DataBinding::LookupError.new("DataBinding 'hiera': #{detail.message}")
    error.set_backtrace(detail.backtrace)
    raise error
  end
end
