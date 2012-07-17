require 'mixlib/cli'

# The souffle application class for both server and worker.
class Souffle::Application
  include Mixlib::CLI

  class Wakeup < Exception
  end

  # Initialize the application, setting up default handlers.
  def initialize
    super

    trap("TERM") do
      Souffle::Application.fatal!("SIGTERM received, stopping", 1)
    end

    trap("INT") do
      Souffle::Application.fatal!("SIGINT received, stopping", 2)
    end

    trap("QUIT") do
      Souffle::Log.info("SIGQUIT received, call stack:\n ", caller.join("\n "))
    end

    trap("HUP") do
      Souffle::Log.info("SIGHUP received, reconfiguring")
      reconfigure
    end
  end

  def reconfigure
    configure_souffle
    configure_logging
  end

  def configure_souffle
    parse_options
  end

  def configure_logging
    Souffle::Log.init(Souffle::Config[:log_location])
    if ( Souffle::Config[:log_location] != STDOUT ) && STDOUT.tty? &&
      ( !Souffle::Config[:daemonize] )
      stdout_loger = Logger.new(STDOUT)
      STDOUT.sync = true
      stdout_logger = Souffle::Log.logger.formatter
      Souffle::Log.loggers << stdout_logger
    end
    Souffle::Log.level = Souffle::Config[:log_level]
  end

  def run
    reconfigure
    setup_application
    run_application
  end

  def setup_application
    error_msg = "#{self.to_s}: you must override setup_application"
    raise Souffle::Exceptions::Application, error_msg
  end

  def run_application
    error_msg = "#{self.to_s}: you must override run_application"
    raise Souffle::Exceptions::Application, error_msg
  end

  class << self

    # # Writes a debug stracktrace to a
    # def debug_stacktrace(e)
    #   message = "#{e.class}: #{e}\n#{e.backtrace.join("\n")}"
    #   stacktrace_out = "Generated at #{Time.now.to_s}\n"
    #   stacktrace_out += message

    #   # Souffle::Log.fatal("Stacktrace dumped to ")
    #   Souffle::Log.debug(message)
    # end

    # Log a fatal error message to both STDERR and the Logger,
    # exit the application with a fatal message.
    #
    # @param [ msg ] String The message to log.
    # @param [ err ] Integer The exit level.
    def fatal!(msg, err = -1)
      Souffle::Log.fatal(msg)
      Process.exit err
    end

    # Log a fatal error message to both STDERR and the Logger,
    # exit the application with a debug message.
    #
    # @param [ msg ] String The message to log.
    # @param [ err ] Integer The exit level.
    def exit!(msg, err = -1)
      Souffle::Log.debug(msg)
      Process.exit err
    end
  end
end
