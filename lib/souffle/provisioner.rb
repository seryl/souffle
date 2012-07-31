module Souffle
  # Starts up the base provisioner class with system and node state machines.
  class Provisioner; end
end

require 'souffle/provisioner/node'
require 'souffle/provisioner/system'

# Starts up the base provisioner class with system and node state machines.
class Souffle::Provisioner
  attr_reader :provider, :system

  # Creates a new provisioner, defaulting to using Vagrant as a provider.
  def initialize
    @provider = initialize_provider
  end

  # Creates the system object from a hash and raises an exception on errors.
  # 
  # @param [ Hash ] system_hash The system represented in hash format.
  def setup_system(system_hash)
    begin
    @system = Souffle::System.from_hash(system_hash)
    rescue
      puts "er"
      # raise Souffle::Exceptions::
    end
  end

  # Cleans up the provider name to match the providers we have.
  # 
  # @param [ String ] provider The name of the provider to use.
  # 
  # @return [ String ] The cleaned up provider name.
  def cleanup_provider(provider)
    case provider.downcase
    when /aws/
      "AWS"
    when /vagrant/
      "Vagrant"
    else
      provider
    end
  end

  # Sets up the given provider to be used for the creation of a system.
  def initialize_provider
    provider = cleanup_provider(Souffle::Config[:provider])
    Souffle::Provider.const_get(provider).new
  rescue
    raise Souffle::Exceptions::InvalidProvider,
      "The provider Souffle::Provider::#{provider} does not exist."
  end

  # Proxy to the provider setup routine.
  def setup_provider
    @provider.setup
  end
end
