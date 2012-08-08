require 'state_machine'

# The system provisioning statemachine.
class Souffle::Provisioner::System

  state_machine :state, :initial => :uninitialized do
    after_transition any => :initializing, :do => :create

    event :reclaimed do
      transition any => :creating
    end

    event :initialized do
      transition :initializing => :creating
    end

    event :created do
      transition :creating => :complete
    end

    event :error_occurred do
      transition any => :handling_error
    end

    event :creation_halted do
      transition any => :failed
    end

    around_transition do |system, transition, block|
      start = Time.now
      block.call
      system.time_used += Time.now - start
    end
  end

  # Creates a new system 
  def initialize(system, max_failures=3)
    super() # NOTE: This is here to initialize state_machine.
    @failures = 0
    @system = system
    initialized
  end

  # Creates the system from an api or command.
  # 
  # @param [ String ] tag The tag to use for the system.
  def create(tag="souffle")
    Souffle::Log.info "[#{system_tag}] Creating a new system..."
    @provider.create_system(@system, tag)
  end

  # Kills the system.
  def kill_system
    @provider.kill(@system.nodes)
  end

  # Handles the error state and recreates the system
  def handle_error
    @failures += 1
    if @failures >= max_failures
      Souffle::Log.error "[#{system_tag}] Complete failure. Halting Creation."
      creation_halted
    else
      err_msg =  "[#{system_tag}] Error creating system. "
      err_msg << "Killing and recreating..."
      Souffle::Log.error(err_msg)
      kill_system
      reclaimed
    end
  end

  private

  # Helper function for the system tag.
  # 
  # @param [ String ] The system or global tag.
  def system_tag
    @system.try_opt(:tag)
  end
end
