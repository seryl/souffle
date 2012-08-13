require 'fileutils'

# The souffle cloud provider class.
class Souffle::Provider
  attr_accessor :system

  # Initialize a new provider for a given system.
  # 
  # @param [ Souffle::System ] system The system to provision.
  def initialize(system=Souffle::System.new)
    add_helpers(system)
    create_ssh_dir_if_missing
  end

  # The name of the given provider. Intended to be overridden.
  def name; "Base"; end

  # Extends a node with the current provider's helper functions.
  # 
  # @param [ Souffle::System ] system The system to extend with helpers.
  def add_helpers(system)
    @system ||= system
    # @system.send(:extend, helper(:System))
    # @system.nodes.each { |node| node.send(:extend, helper(:Node)) }
  end

  # Wait until ssh is available for the node and then connect.
  def boot(node, retries=50)
  end

  # Creates a system for a given provider. Intended to be overridden.
  #
  # @raise [Souffle::Exceptions::Provider] This definition must be overrridden.
  # 
  # @param [ Souffle::System ] system The system to instantiate.
  # @param [ String ] tag The tag to use for the system.
  def create_system(system, tag="souffle")
    error_msg = "#{self.class.to_s}: you must override create_system"
    raise Souffle::Exceptions::Provider, error_msg
  end

  # Takes a node definition and begins the provisioning process.
  # 
  # @param [ Souffle::Node ] node The node to instantiate.
  # @param [ String ] tag The tag to use for the node.
  def create_node(node, tag=nil)
    error_msg = "#{self.class.to_s}: you must override create_node"
    raise Souffle::Exceptions::Provider, error_msg
  end

  # Creates a raid array for a given provider. Intended to be overridden.
  # 
  # @raise [Souffle::Exceptions::Provider] This definition must be overridden.
  def create_raid
    error_msg = "#{self.class.to_s}: you must override create_raid"
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

  # Waits for ssh to be accessible for a node for the initial connection and
  # yields an ssh object to manage the commands naturally from there.
  # 
  # @param [ String ] address The address of the machine to connect to.
  # @param [ String ] user The user to connect as.
  # @param [ String, NilClass ] pass By default publickey and password auth
  # will be attempted.
  # @param [ Hash ] opts The options hash.
  # @param [ Fixnum ] timeout The timeout for ssh boot.
  # @option opts [ Hash ] :net_ssh Options to pass to Net::SSH,
  # see Net::SSH.start
  # @option opts [ Hash ] :timeout (TIMEOUT) default timeout for all #wait_for
  # and #send_wait calls.
  # @option opts [ Boolean ] :reconnect When disconnected reconnect.
  # 
  # @yield [ Eventmachine::Ssh:Session ] The ssh session.
  def wait_for_boot(address, user="root", pass=nil, opts={},
                    timeout=200)
    Souffle::Log.info "Waiting for ssh for #{address}..."
    timer = EM::PeriodicTimer.new(EM::Ssh::Connection::TIMEOUT) do
      opts[:password] = pass unless pass.nil?
      opts[:paranoid] = false
      EM::Ssh.start(address, user, opts) do |connection|
        connection.errback  { |err| nil }
        connection.callback do |ssh|
          yield(ssh) if block_given?
          ssh.close
        end
      end
    end

    EM::Timer.new(timeout) do
      Souffle::Log.error "SSH Boot timeout for #{address}..."
      timer.cancel
    end
  end

  # Yields an ssh object to manage the commands naturally from there.
  # 
  # @param [ String ] address The address of the machine to connect to.
  # @param [ String ] user The user to connect as.
  # @param [ String, NilClass ] pass By default publickey and password auth
  # will be attempted.
  # @param [ Hash ] opts The options hash.
  # @option opts [ Hash ] :net_ssh Options to pass to Net::SSH,
  # see Net::SSH.start
  # @option opts [ Hash ] :timeout (TIMEOUT) default timeout for all #wait_for
  # and #send_wait calls.
  # @option opts [ Boolean ] :reconnect When disconnected reconnect.
  # 
  # @yield [ EventMachine::Ssh::Session ] The ssh session.
  def ssh_block(address, user="root", pass=nil, opts={})
    opts[:password] = pass unless pass.nil?
    opts[:paranoid] = false
    EM::Ssh.start(address, user, opts) do |connection|
      connection.errback do |err|
        Souffle::Log.error "SSH Error: #{err} (#{err.class})"
      end
      connection.callback { |ssh| yield(ssh) if block_given?; ssh.close }
    end
  end

  # The path to the ssh key with the given name.
  # 
  # @param [ String ] key_name The name fo the ssh key to lookup.
  # 
  # @return [ String ] The path to the ssh key with the given name.
  def ssh_key(key_name)
    "#{ssh_key_path}/#{key_name}"
  end

  # Grabs an ssh key for a given aws node.
  # 
  # @param [ String ] key_name The name fo the ssh key to lookup.
  # 
  # @return [ true,false ] Whether or not the ssh_key exists for the node.
  def ssh_key_exists?(key_name)
    File.exists? ssh_key(key_name)
  end

  # Creates the ssh directory for a given provider if it does not exist.
  def create_ssh_dir_if_missing
    FileUtils.mkdir_p(ssh_key_path) unless Dir.exists?(ssh_key_path)
  rescue
    raise PermissionErrorSshKeys,
      "The ssh key directory does not have write permissions: #{ssh_key_path}"
  end

  # The path to the ssh keys for the provider.
  # 
  # @return [ String ] The path to the ssh keys for the provider.
  def ssh_key_path
    File.join(File.dirname(
      Souffle::Config[:config_file]), "ssh", name.downcase)
  end

end
