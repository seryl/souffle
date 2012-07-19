require 'souffle/provider'

# The Vagrant souffle provider.
class Souffle::Provider::Vagrant < Souffle::Provider

  # Setup the internal Vagrant configuration and object.
  def setup
  end

  # The name of the given provider.
  def name; "Vagrant"; end

  # Noop.
  def create_raid; end
end
