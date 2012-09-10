require 'souffle/redis_client'

class Souffle::State
  class << self

    # The Souffle::State prefix for Redis.
    def prefix
      "souffle_state_"
    end

    # Returns the current system states.
    def status
      Souffle::Redis.get("#{Souffle::State.prefix}status")
    end
  end
end
