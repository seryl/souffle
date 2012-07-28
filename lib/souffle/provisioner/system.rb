require 'state_machine'

# The system provisioning statemachine.
class Souffle::Provisioner::System

  state_machine :state, :initial => :uninitialized do
    event :init do
      transition [:uninitialized, :failure] => :provisioning
    end

    event :boot do
      transition [:initializing] => :ready
    end

    event :provision do
      transition [:ready] => :provisioning
    end

    event :failure do
      transition any => :failed
    end

    around_transition do |system, transition, block|
      start = Time.now
      block.call
      system.time_used += Time.now - start
    end
  end

  def initialize
    super() # NOTE: This is here to initialize state_machine.
  end
end
