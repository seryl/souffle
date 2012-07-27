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
end
