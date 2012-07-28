require 'state_machine'

# The system provisioning statemachine.
class Souffle::Provisioner::System

  state_machine :state, :initial => :uninitialized do
    after_transition any => :initializing, :do => :create

    around_transition do |system, transition, block|
      start = Time.now
      block.call
      system.time_used += Time.now - start
    end
  end

  def initialize(system, max_failures=3)
    super() # NOTE: This is here to initialize state_machine.
  end

  # Creates the system from an api or command.
  def create
    Souffle::Log.info "Creating a new system"
  end

  # Kills the system entirely.
  def kill
  end

  # Kills the system and restarts the creation loop.
  def kill_and_recreate
  end
end
