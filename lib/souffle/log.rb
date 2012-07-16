require 'logger'
require 'mixlib/log'

module Souffle
  # Souffle's internal logging facility.
  # Standardized to provide a consistent log format.
  class Log
    extend Mixlib::Log

    # Force initialization of the primary log device (@logger)
    init

    class Formatter
      def self.show_time=(*args)
        Mixlib::Log::Formatter.show_time = *args
      end
    end

  end
end
