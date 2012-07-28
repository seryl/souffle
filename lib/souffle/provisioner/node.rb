require 'state_machine'

# The node provisioning statemachine.
class Souffle::Provisioner::Node

  state_machine :state, :initial => :uninitialized do
    after_transition any => :initializing, :do => :create
    after_transition any => :booting, :do => :boot
    after_transition any => :provisioning, :do => :provision

    event :init do
      transition [:uninitialized, :failure] => :initializing
    end

    event :boot do
      transition [:initializing] => :booting
    end

    event :failure do
      transition any => :failed
    end

    event :max_failures do
      transition any => :kill_and_recreate
    end

    around_transition do |system, transition, block|
      start = Time.now
      block.call
      system.time_used += Time.now - start
    end
  end

  def initialize(node, max_failures=3)
    @max_failures = max_failures
    super() # NOTE: This is here to initialize state_machine.
  end

  # Creates the machine from an api or command.
  def create
  end

  # Boots up the machine and waits for ssh.
  def boot
  end

  # Provisions the ebs/raid/shares/etc and then starts the chef run.
  def provision
  end

  # Kills the node entirely.
  def kill
  end

  # Kills the node and restarts the creation loop.
  def kill_and_recreate
  end
end
