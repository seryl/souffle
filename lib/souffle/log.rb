$:.unshift File.dirname(__FILE__)
require 'log/formatter'

module Souffle
  # Souffle's internal logging facility.
  # Standardized to provide a consistent log format.
  class Log
    @logger = nil
    @setup_has_run = false

    # Logging levels with a symbol lookup.
    LEVELS = {
      :debug => Logger::DEBUG,
      :info  => Logger::INFO,
      :warn  => Logger::WARN,
      :error => Logger::ERROR,
      :fatal => Logger::FATAL }

    class << self
      attr_accessor :logger, :level, :file

      # Use Souffle::Log.init when you want to setup the logger maually.
      #
      # If this method is called with no arguments, it will log to STDOUT
      # at the :info level.
      #
      # It also configures the Logger instance it creates to use the custom
      # Souffle::Log::Formatter class.
      def init(path = nil)
        case path
        when "","/dev/null"
          @file = "/dev/null"
        when nil
          @file = STDOUT
        else
          @file = File.join(path, "#{logfile}.log")
        end

        @logger = Logger.new(file)
        @logger.formatter = Souffle::Log::Formatter.new
        Log.level = :info
      end

      # Sets the level for te Logger by symbol or by command line argument.
      # Throws an ArgumentError if you feed it a bogus log level (that is not
      # one of the items in `LEVELS`, a corresponding logger string,
      # or a valid Logger level)
      #
      # @param [ String, Integer, Symbol ] loglevel The logging level to use.
      #
      # @return [ Integer ] The logging level to use.
      def level=(loglevel)
        init unless @logger
        lvl = case loglevel
              when String then loglevel.intern
              when Integer then LEVELS.invert[loglevel]
              else loglevel
              end

        unless LEVELS.include?(lvl)
          raise(ArgumentError,
                'Log level must be one of :debug, :info, :warn, :error or :fatal')
        end

        unless @setup_has_run
          @logger.level = 1
          @setup_has_run = true
        end

        unless @logger.level.eql? LEVELS[lvl]
          @logger.info "[setup] Setting log level to #{lvl.to_s.upcase}"
          @level = lvl
          @logger.level = LEVELS[lvl]
        end
      end
    end

  end
end
