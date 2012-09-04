require 'logger'
require 'mixlib/log'

# Souffle's internal logging facility.
# Standardized to provide a consistent log format.
class Souffle::Log
  extend Mixlib::Log

  # Force initialization of the primary log device (@logger).
  init

  # Monkeypatch Formatter to allow local show_time updates.
  class Formatter
    # Allow enabling and disabling of time with a singleton.
    def self.show_time=(*args)
      Mixlib::Log::Formatter.show_time = *args
    end
  end
end
