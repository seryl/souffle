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
    :short => "-L LOG_LOCATION",
    :long =>  "--logfile LOG_LOCATION",
    :description => "Set the log file location, defaults to STDOUT",
    :proc => nil

  option :user,
    :short => "-u USER",
    :long => "--user USER",
    :description => "User to set privilege to",
    :proc => nil

  option :group,
    :short => "-g GROUP",
    :long => "--group GROUP",
    :description => "Group to set privilege to",
    :proc => nil

  option :daemonize,
    :short => "-d",
    :long  => "--daemonize",
    :default => false,
    :description => "Run the application as a daemon (forces `-s`)",
    :proc => lambda { |p| true }

  option :environment,
    :short => "-E",
    :long  => "--environment",
    :description => "The environment profile to use",
    :proc => nil

  option :rack_host,
    :short => "-H HOSTNAME",
    :long  => "--hostname HOSTNAME",
    :description => "Hostname to listen on (default: 0.0.0.0)",
    :proc => nil

  option :rack_port,
    :short => "-P PORT",
    :long  => "--port PORT",
    :description => "Port to listen on (default: 8080)",
    :proc => lambda { |p| p.to_i }

  option :vagrant_dir,
    :short => "-V VAGRANT_DIR",
    :long  => "--vagrant_dir VAGRANT_DIR",
    :description => "The path to the base vagrant vm directory",
    :proc => nil

  option :pid_file,
    :short => "-f PID_FILE",
    :long  => "--pid PID_FILE",
    :description => "Set the PID file location, defaults to /tmp/souffle.pid",
    :proc => nil

  option :provider,
    :short => "-p PROVIDER",
    :long  => "--provider PROVIDER",
    :description => "The provider to use (overrides config)",
    :proc => nil

  option :json,
    :short => "-j JSON",
    :long  => "--json JSON",
    :description => "The json for a single provision (negates `-s`)",
    :proc => nil

  option :server,
    :short => "-s",
    :long  => "--server",
    :default => false,
    :description => "Start the application as a server",
    :proc => nil

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
    Souffle::Daemon.change_privilege
    Souffle::Config[:server] = true if Souffle::Config[:daemonize]
    @app = Souffle::Server.new
  end

  # Runs the Souffle Server.
  def run_application
    if Souffle::Config[:daemonize]
      Souffle::Config[:server] = true
      Souffle::Daemon.daemonize("souffle")
    end
    @app.run
  end
end
