require 'puppet/indirector'
require 'puppet/indirector/yaml'
require 'puppet/node/patches'

class Puppet::Node::Patches::Yaml < Puppet::Indirector::Yaml
  desc "Retrieve patch state from a yaml file for all roles on a node."

  class Puppet::Node::Patches::NoPatchFile < Exception; end

  def find(request)
    node = request.key
    file        = request.options[:file] || 'patches.yaml'

    path = File.join( Puppet[:environmentpath], node.environment.to_s, 'patches', file )

    unless File.exists?(path)
      raise Puppet::Node::Patches::NoPatchFile, "Puppet patch file #{path} doesn't exist"
    end

    all_patches = YAML::load(IO.read(path))
    patches_to_be_applied = Hash.new

    classes_with_patches = node.classes.select { |c| all_patches.has_key?(c) }
    classes_with_patches.each do |klass|
      role = klass.first
      puts all_patches[role]
      patches_to_be_applied.merge! all_patches[role]
    end

    patches_to_be_applied
  end
end
