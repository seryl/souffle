require 'souffle/application'
require 'souffle/server'

# The souffle server command line parser.
class Souffle::Application::Server < Souffle::Application

  option :config_file,
    :short => "-c CONFIG",
    :long  => "--config CONFIG",
    :default => "/etc/souffle/souffle.rb",
    :description => "The configuration file to use"

  option :log_level,
    :short => "-l LEVEL",
    :long  => "--log_level LEVEL",
    :description => "Set the log level (debug, info, warn, error, fatal)",
    :proc => lambda { |l| l.to_sym }

  option :log_location,
    :short => "-L LOGLOCATION",
    :long =>  "--logfile LOGLOCATION",
    :description => "Set the log file location, defaults to STDOUT",
    :proc => nil

  option :provider,
    :short => "-p PROVIDER",
    :long  => "--provider PROVIDER",
    :default => nil,
    :description => "The provider to use (overrides config)"

  option :daemonize,
    :short => "-d",
    :long  => "--daemon",
    :default => false,
    :description => "Run the application as a daemon (forces `-s`)"

  option :server,
    :short => "-s",
    :long  => "--server",
    :default => false,
    :description => "Start the application as a server"

  option :help,
    :short => "-h",
    :long  => "--help",
    :description => "Show this message",
    :on => :tail,
    :boolean => true,
    :show_options => true,
    :exit => 0

  option :version,
    :short => "-v",
    :long  => "--version",
    :description => "Show souffle version",
    :boolean => true,
    :proc => lambda { |v| puts "Souffle: #{::Souffle::VERSION}"},
    :exit => 0

  # Grabs all of the cli parameters and generates the mixlib config object.
  def initialize
    super
  end

  # Configures the souffle server based on the cli parameters.
  def setup_application
    @app = Souffle::Server.new
  end

  # Runs the Souffle Server.
  def run_application
    @app.run
  end
end
