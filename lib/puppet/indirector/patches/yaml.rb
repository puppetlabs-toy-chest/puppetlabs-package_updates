require 'puppet/indirector'
require 'puppet/indirector/yaml'
require 'puppet/node/patches'

class Puppet::Node::Patches::Yaml < Puppet::Indirector::Yaml
  desc "Retrieve patch state from a yaml file for all roles on a node."

  def find(request)
    node = request.key
    file = request.options[:file] || 'patches.yaml'

    path = File.join( Puppet[:environmentpath], node.environment.to_s, 'patches', file )

    unless File.exists?(path)
      raise Puppet::Node::Patches::NoPatchFile, "Puppet patch file #{path} doesn't exist"
    end

    YAML::load(IO.read(path))
  end
end
