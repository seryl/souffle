require 'mixlib/cli'

# The souffle application class for both server and worker.
class Souffle::Application
  include Mixlib::CLI

  # The commands that were left unparsed from parse_options.
  attr_accessor :commands

  # Added a Wakeup exception.
  class Wakeup < Exception; end

  # Initialize the application, setting up default handlers.
  def initialize
    @commands = []
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

  # Reconfigure the application and logging.
  def reconfigure
    configure_souffle
    configure_logging
  end

  # Configure the application throwing a warning when there is no config file.
  def configure_souffle
    parse_options

    begin
      ::File.open(config[:config_file]) { |f| apply_config(f.path) }
    rescue Errno::ENOENT => error
      msg =  "Did not find the config file: #{config[:config_file]}"
      msg << ", Using command line options."
      Souffle::Log.warn "*****************************************"
      Souffle::Log.warn msg
      Souffle::Log.warn "*****************************************"
    end
  end

  # Configures the logging in a relatively sane fashion.
  # Only prints to STDOUT given a valid tty.
  # Does not write to STDOUT when daemonizing.
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

  # Run the application itself. Configure, setup, and then run.
  def run
    reconfigure
    setup_application
    run_application
  end

  # Placeholder for setup_application, intended to be overridden.
  # 
  # @raise Souffle::Exceptions::Application Must be overridden.
  def setup_application
    error_msg = "#{self.to_s}: you must override setup_application"
    raise Souffle::Exceptions::Application, error_msg
  end

  # Placeholder for run_application, intended to be overridden.
  # 
  # @raise Souffle::Exceptions::Application Must be overridden.
  def run_application
    error_msg = "#{self.to_s}: you must override run_application"
    raise Souffle::Exceptions::Application, error_msg
  end

  private

  # Apply the configuration given a file path.
  # 
  # @param [ String ] config_file_path The path to the configuration file.
  def apply_config(config_file_path)
    Souffle::Config.from_file(config_file_path)
    Souffle::Config.merge!(config)
  end

  class << self
    # Present a debug stracktrace upon an error.
    # Gives a readable backtrace with a timestamp.
    # 
    # @param [ Exception ] e The raised exception.
    def debug_stacktrace(e)
      message = "#{e.class}: #{e}\n#{e.backtrace.join("\n")}"
      stacktrace_out = "Generated at #{Time.now.to_s}\n"
      stacktrace_out += message

      Souffle::Log.debug(message)
    end

    # Log a fatal error message to both STDERR and the Logger,
    # exit the application with a fatal message.
    #
    # @param [ String ] msg The message to log.
    # @param [ Fixnum ] err The exit level.
    def fatal!(msg, err = -1)
      Souffle::Log.fatal(msg)
      Process.exit err
    end

    # Log a fatal error message to both STDERR and the Logger,
    # exit the application with a debug message.
    #
    # @param [ String ] msg The message to log.
    # @param [ Fixnum ] err The exit level.
    def exit!(msg, err = -1)
      Souffle::Log.debug(msg)
      Process.exit err
    end
  end
end
