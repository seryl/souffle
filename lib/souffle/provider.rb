# The souffle cloud provider class.
class Souffle::Provider
  
  # The setup method for the provider. Intended to be overridden.
  # 
  # @raise [Souffle::Exceptions::Provider] This definition must be overridden.
  def setup
    error_msg = "#{self.to_s}: you must override setup"
    raise Souffle::Exceptions::Provider, error_msg
  end

  # The name of the given provider. Intended to be overridden.
  # 
  # @raise [Souffle::Exceptions::Provider] This definition must be overridden.
  def name
    error_msg = "#{self.to_s}: you must override name"
    raise Souffle::Exceptions::Provider, error_msg
  end

  # Extends a node with the current provider's helper functions.
  # 
  # @param [ Souffle::System ] system The system to extend with helpers.
  def add_helpers(system)
    system.send(:extend, helper(:System))
    system.nodes.each { |node| node.send(:extend, helper(:Node)) }
  end

  # Creates a system for a given provider. Intended to be overridden.
  #
  # @raise [Souffle::Exceptions::Provider] This definition must be overrridden.
  # 
  # @param [ Souffle::System ] system The system to instantiate.
  def create_system(system)
    error_msg = "#{self.to_s}: you must override create_system"
    raise Souffle::Exceptions::Provider, error_msg
  end

  # Takes a node definition and begins the provisioning process.
  # 
  # @param [ Souffle::Node ] node The node to instantiate.
  def create_node(node)
    error_msg = "#{self.to_s}: you must override create_node"
    raise Souffle::Exceptions::Provider, error_msg
  end

  # Creates a raid array for a given provider. Intended to be overridden.
  # 
  # @raise [Souffle::Exceptions::Provider] This definition must be overridden.
  def create_raid
    error_msg = "#{self.to_s}: you must override create_raid"
    raise Souffle::Exceptions::Provider, error_msg
  end

  # Helper modules for extending node functionality based on a provider.
  module Helpers; end

  private

  # Helper function to get the helper module and children.
  # 
  # @param [ Symbol ] mod The provider module helper to select.
  # 
  # @return [ Module ] The provider helper module.
  def helper(mod)
    Souffle::Provider::Helpers.const_get(name).const_get(mod)
  end
end
