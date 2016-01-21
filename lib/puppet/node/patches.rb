require 'puppet/node'
require 'puppet/indirector'

class Puppet::Node::Patches
  Puppet::ResourceType = self

  class Puppet::Node::Patches::NoPatchFile < Exception; end

  extend Puppet::Indirector

  indirects :patches, :terminus_class => :hiera
end
