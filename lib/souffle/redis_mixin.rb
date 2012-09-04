require 'eventmachine'
require 'redis'

# A singleton mixin adapter similar to mixlib/log.
# 
# @example
# 
#   require 'souffle/redis_mixin'
# 
#   class MyRedis
#     extend Souffle::RedisMixin
#   end
# 
#   MyRedis.set('awesome', 'cool')
#   MyRedis.get('awesome')
# 
module Souffle::RedisMixin
  attr_reader :redis

  # Initializes the redis client (uses synchrony if Eventmachine is running).
  def init(*opts)
    if EM.reactor_running?
      @redis ||= Redis.new({ :driver => :synchrony }.merge(*opts))
    else
      @redis ||= Redis.new(*opts)
    end
  end

  # The singleton redis object, initializes if it doesn't exist.
  def redis
    @redis || init
  end

  # Pass any other method calls to the underlying redis object created with
  # init. If this method is hit before the call to Souffle::RedisMixin.init
  # has been made, it will call Souffle::RedisMixin.init() with no arguments.
  def method_missing(method_symbol, *args, &blk)
    redis.send(method_symbol, *args, &blk)
  end
end
