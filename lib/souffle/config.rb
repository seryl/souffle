require 'souffle/log'
require 'mixlib/config'
require 'yajl'

# The configuration object for the souffle server.
class Souffle::Config
  extend Mixlib::Config

  # Return the configuration itself upon inspection.
  def self.inspect
    configuration.inspect
  end

  # Loads a given file and passes it to the appropriate parser.
  #
  # @raise [ IOError ] Any IO Exceptions that occur.
  #
  # @param [ String ] filename The filename to read.
  def self.from_file(filename, parser="ruby")
    send("from_file_#{parser}".to_sym, filename)
  end

  # Loads a given ruby file and runs instance_eval against it
  # in the context of the current object.
  #
  # @raise [ IOError ] Any IO Exceptions that occur.
  #
  # @param [ String ] filename The file to read.
  def self.from_file_ruby(filename)
    self.instance_eval(IO.read(filename), filename, 1)
  end

  # Loads a given json file and merges the current context
  # configuration with the updated hash.
  #
  # @raise [ IOError ] Any IO Exceptions that occur.
  # @raise [ Yajl::ParseError ] Raises Yajl Parsing error on improper json.
  #
  # @param [ String ] filename The file to read.
  def self.from_file_json(filename)
    self.from_stream_json(IO.read(filename))
  end

  # Loads a given json input and merges the current context
  # configuration with the updated hash.
  #
  # @raise [ IOError ] Any IO Exceptions that occur.
  # @raise [ Yajl::ParseError ] Raises Yajl Parsing error on improper json.
  #
  # @param [ String ] input The json configuration input.
  def self.from_stream_json(input)
    parser = Yajl::Parser.new(:symbolize_keys => true)
    configuration.merge!(parser.parse(input))
  end

  # When you are using ActiveSupport, they monkey-patch 'daemonize' into
  # Kernel. So while this is basically identical to what method_missing
  # would do, we pull it up here and get a real method written so that
  # things get dispatched properly.
  config_attr_writer :daemonize do |v|
    configure do |c|
      c[:daemonize] = v
    end
  end

  # Logging Settings
  log_level :info
  log_location STDOUT

  # Daemonization Settings
  user nil
  group nil
  umask 0022

  pid_file nil

  # AWS Settings
  aws_access_key ""
  aws_access_secret ""

  # Rack Settings
  rack_host "0.0.0.0"
  rack_port 8080
  rack_environment "development"

  # Vagrant Settings
  vagrant_dir "#{ENV['HOME']}/vagrant/vms"
end
