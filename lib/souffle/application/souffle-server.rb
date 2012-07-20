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
    :short        => "-L LOGLOCATION",
    :long         => "--logfile LOGLOCATION",
    :description  => "Set the log file location, defaults to STDOUT",
    :proc         => nil

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

  def initialize
    super

  end
end
