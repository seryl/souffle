module Souffle
  # Starts up the base provisioner class with system and node state machines.
  class Provisioner; end
end

require 'souffle/provisioner/node'
require 'souffle/provisioner/system'

# Starts up the base provisioner class with system and node state machines.
class Souffle::Provisioner
  attr_reader :provider

  # Creates a new provisioner, defaulting to using Vagrant as a provider.
  # 
  # @param [ String ] provider The provider to use for the provisioner.
  def initialize(provider="Vagrant")
    @provider = initialize_provider(provider)
  end

  # Sets up the given provider to be used for the creation of a system.
  # 
  # @param [ String ] provider The provider to use for system creation.
  def initialize_provider(provider)
    Souffle::Provider.const_get(provider.to_sym).new
  rescue
    raise Souffle::Exceptions::InvalidProvider,
      "The provider Souffle::Provider::#{provider} does not exist."
  end

  # Proxy to the provider setup routine.
  def setup_provider
    @provider.setup
  end
end
