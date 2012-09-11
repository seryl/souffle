require 'souffle/redis_client'
require 'eventmachine'

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

    # Begins the state service update poller.
    def start_service
      @svc_timer ||= EM.add_periodic_timer(120) do
      end
    end

    # Stops the state service.
    def stop_service
      @svc_timer.cancel if @svc_timer.respond_to?(:cancel)
    end
  end
end
