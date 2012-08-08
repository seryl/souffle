require 'state_machine'

# The node provisioning statemachine.
class Souffle::Provisioner::Node

  state_machine :state, :initial => :uninitialized do
    after_transition any => :handling_error, :do => :error_handler
    after_transition any => :initializing, :do => :create
    after_transition :creating => :booting, :do => :boot
    after_transition :booting => :partitioning_device,
                          :do => :partition_device
    after_transition :partitioning_device => :setup_mdadm,
                          :do => :install_mdadm
    after_transition :installing_mdadm => :formatting_device,
                          :do => :format_device
    after_transition any => :provisioning, :do => :provision

    event :initialized do
      transition :initializing => :creating
    end

    event :created do
      transition :creating => :booting
    end

    event :booted do
      transition :booting => :partitioning_device
    end

    event :partitioning_device do
      transition :partitioning_device => :installing_mdadm
    end

    event :mdadm_installed do
      transition :installing_mdadm => :formatting_device
    end

    event :device_formatted do
      transition :formatting_device => :initializing_raid
    end

    event :raid_initialized do
      transition :initializing_raid => :provisioning
    end

    event :provisioned do
      transition :provisioning => :complete
    end

    event :error_occurred do
      transition any => :handling_error
    end

    event :failed do
      transition any => :handling_failure
    end

    around_transition do |system, transition, block|
      start = Time.now
      block.call
      system.time_used += Time.now - start
    end
  end

  # Creates a new node provisioner state machine.
  # 
  # @param [ Souffle::Node ] node The node to manage.
  # @param [ Fixnum ] max_failures The maximum number of failures.
  def initialize(node, max_failures=3)
    super() # NOTE: This is here to initialize state_machine.
    @node = node
    @max_failures = max_failures
  end

  # Creates the node from an api or command.
  def create
    Souffle::Log.info "[#{node_tag}: #{node.name}] Creating a new node..."
  end

  # Boots up the node and waits for ssh.
  def boot
    Souffle::Log.info "[#{node_tag}: #{node.name}] Booting node..."
  end

  # Installs and sets up mdadm.
  def setup_mdadm
    Souffle::Log.info "[#{node_tag}: #{node.name}] Setting up mdadm..."
  end

  # Partitions the soon to be raid device.
  def partition_device
    Souffle::Log.info "[#{node_tag}: #{node.name}] Partitioning the device..."
  end

  # Formats a device to the configured filesystem.
  def format_device
    Souffle::Log.info "[#{node_tag}: #{node.name}] Formatting the device..."
  end

  # Sets up raid to the configured raid-level.
  def setup_raid
    Souffle::Log.info "[#{node_tag}: #{node.name}] Setting up raid..."
  end

  # Provisions the ebs/raid/shares/etc and then starts the chef run.
  def provision
    Souffle::Log.info "[#{node_tag}: #{node.name}] Provisioning node..."
  end

  # Kills the node entirely.
  def kill
    Souffle::Log.info "[#{node_tag}: #{node.name}] Killing node..."
  end

  # Kills the node and restarts the creation loop.
  def kill_and_recreate
    Souffle::Log.info "[#{node_tag}: #{node.name}] Recreating node..."
  end

  private

  # Helper_function for the node's tag.
  # 
  # @return [ String ] The node, system, or global tag.
  def node_tag
    @node.try_opt(:tag)
  end
end
