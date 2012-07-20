require 'souffle/provider'

# The Vagrant souffle provider.
class Souffle::Provider::Vagrant < Souffle::Provider
  attr_reader :vagrant_dir

  # Setup the internal Vagrant configuration and object.
  def setup
    @vagrant_dir = Souffle::Config[:vagrant_dir]
  end

  # The name of the given provider.
  def name; "Vagrant"; end

  # Noop.
  def create_raid; end
end
