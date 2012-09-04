require 'souffle/redis_mixin'

class Souffle::Redis
  extend Souffle::RedisMixin

  # Force initialization of the redis client (@redis).
  init
end
