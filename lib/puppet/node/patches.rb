require 'puppet/node'
require 'puppet/indirector'

class Puppet::Node::Patches
  Puppet::ResourceType = self

  class Puppet::Node::Patches::NoPatchFile < Exception; end

  extend Puppet::Indirector

  indirects :patches, :terminus_class => :hiera

  def self.find(node)
    all_patches = self.indirection.find(node)

    patches_to_be_applied = Hash.new

    # If the patch hash has classes with updates, find
    # the updates for classes on this node
    if all_patches.has_key?('classes')
      classes_with_patches = node.classes.select { |c| all_patches['classes'].has_key?(c) }
      classes_with_patches.each do |klass|
        role = klass.first
        patches_to_be_applied.merge! all_patches['classes'][role]
      end

      # This key isn't needed anymore.
      # All that's left should be global patches
      all_patches.delete('classes')
    end

    # Add in the global patches
    patches_to_be_applied.merge! all_patches

    patches_to_be_applied
  end
end
