require 'souffle/redis_client'

class Souffle::State
  class << self

    # Returns the current system states.
    def status
      Souffle::Redis.get('awesome')
    end
  end
end
