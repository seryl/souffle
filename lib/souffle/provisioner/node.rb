require 'state_machine'

# The node provisioning statemachine.
class Souffle::Provisioner::Node
  attr_accessor :time_used

  state_machine :state, :initial => :initializing do
    after_transition any => :handling_error, :do => :error_handler
    after_transition any => :creating, :do => :create
    after_transition :creating => :booting, :do => :boot
    after_transition :booting => :partitioning_device,
                          :do => :partition_device
    after_transition :partitioning_device => :installing_mdadm,
                          :do => :setup_mdadm
    after_transition :installing_mdadm => :initializing_raid,
                          :do => :setup_raid
    after_transition :initializing_raid => :formatting_device,
                          :do => :format_device
    after_transition :formatting_device => :ready_to_provision,
                          :do => :ready
    after_transition any => :provisioning, :do => :provision
    after_transition any => :complete, :do => :node_provisioned

    event :reclaimed do
      transition any => :creating
    end

    event :initialized do
      transition :initializing => :creating
    end

    event :created do
      transition :creating => :booting
    end

    event :booted do
      transition :booting => :partitioning_device
    end

    event :partitioned_device do
      transition :partitioning_device => :installing_mdadm
    end

    event :mdadm_installed do
      transition :installing_mdadm => :initializing_raid
    end

    event :raid_initialized do
      transition :initializing_raid => :formatting_device
    end

    event :device_formatted do
      transition :formatting_device => :ready_to_provision
    end

    event :begin_provision do
      transition :ready_to_provision => :provisioning
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
    @time_used = 0
    @node = node
    @max_failures = max_failures
    super() # NOTE: This is here to initialize state_machine.
  end

  # Creates the node from an api or command.
  def create
    Souffle::Log.info "#{@node.log_prefix} Creating a new node..."
    provider.create_node(@node)
  end

  # Boots up the node and waits for ssh.
  def boot
    Souffle::Log.info "#{@node.log_prefix} Booting node..."
    provider.boot(@node)
  end

  # Installs and sets up mdadm.
  def setup_mdadm
    Souffle::Log.info "#{@node.log_prefix} Setting up mdadm..."
    provider.setup_mdadm(@node)
  end

  # Partitions the soon to be raid device.
  def partition_device
    Souffle::Log.info "#{@node.log_prefix} Partitioning the device..."
    provider.partition(@node)
  end

  # Formats a device to the configured filesystem.
  def format_device
    Souffle::Log.info "#{@node.log_prefix} Formatting the device..."
    provider.format_device(@node)
  end

  # Sets up raid to the configured raid-level.
  def setup_raid
    Souffle::Log.info "#{@node.log_prefix} Setting up raid..."
    provider.setup_raid(@node)
  end

  # Notify the logger when the node is ready for provisioning.
  def ready
    Souffle::Log.info "#{@node.log_prefix} Is ready for provisioning..."
  end

  # Provisions the given node with a chef/chef-solo run.
  def provision
    Souffle::Log.info "#{@node.log_prefix} Provisioning node..."
    provider.provision(@node)
  end

  # Notifies the system that the current node has completed provisioning.
  def node_provisioned
    Souffle::Log.info "#{@node.log_prefix} Node provisioned."
    system_provisioner.node_provisioned
  end

  # Kills the node entirely.
  def kill
    Souffle::Log.info "#{@node.log_prefix} Killing node..."
    provider.kill(@node)
  end

  # Kills the node and restarts the creation loop.
  def kill_and_recreate
    Souffle::Log.info "#{@node.log_prefix} Recreating node..."
    provider.kill_and_recreate(@node)
  end

  # Handles any 
  def error_handler
    Souffle::Log.info "#{@node.log_prefix} Handling node error..."
  end

  # Helper function for the node's system provider.
  def provider
    @node.provider
  end

  # Helper function for the system provisioner.
  def system_provisioner
    @node.system.provisioner
  end
end
