require 'puppet/node'
require 'puppet/indirector'

class Puppet::Node::Patches
  Puppet::ResourceType = self

  extend Puppet::Indirector

  indirects :patches, :terminus_class => :yaml
end
