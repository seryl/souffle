# The souffle cloud provider class.
class Souffle::Provider
  def initialize
  end

  # The name of the given provider. Intended to be overridden.
  # 
  # @raise [Souffle::Exceptions::Provider] This definition must be overridden.
  def name
    error_msg = "#{self.to_s}: you must override name"
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
