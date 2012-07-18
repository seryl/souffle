require 'souffle/provider'

# The Vagrant souffle provider.
class Souffle::Provider::Vagrant < Souffle::Provider
  
  # The name of the given provider.
  def name; "Vagrant"; end

  # Noop.
  def create_raid; end
end
