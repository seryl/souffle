class Souffle::Provisioner

  state_machine :state, :initial => :uninitialized do
    event :init do
      transition [:uninitialized, :third_failure] => :initializing
    end

    event :boot do
      transition [:initializing] => :ready
    end

    event :provision do
      transition [:ready] => :provisioning
    end

    event :fail do
      transition any => :failure
    end

    around_transition do |system, transition, block|
        start = Time.now
        block.call
        system.time_used += Time.now - start
      end
    end
  end

  def initialize
    super() # NOTE: This is here to initialize state_machine.
  end
end
