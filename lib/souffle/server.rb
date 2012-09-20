require 'thin'
require 'eventmachine'
require 'em-synchrony'
require 'souffle/http'

# The souffle server and management daemon.
class Souffle::Server

  # Creates a new souffle server.
  def initialize
  end

  # Runs the server.
  def run
    if Souffle::Config[:server]
      run_server
    else
      run_instance
    end
  end

  # Gets the rack options from the configuration.
  # 
  # @return [ Hash ] The rack options from Souffle::Config.
  def rack_options
    opts = Hash.new
    Souffle::Config.configuration.each do |k,v|
      if /^rack/ =~ k.to_s
        param = k.to_s.gsub('rack_', '')

        case param
        when "environment"
          opts[param.to_sym] = v
        else
          opts[param.capitalize.to_sym] = v
        end
      end
    end
    opts
  end

  # Starts a long-running webserver that continuously handles requests.
  def run_server
    EM.synchrony do
      @app = Rack::Builder.new do
        use Rack::Lint
        use Rack::ShowExceptions
        run Rack::Cascade.new([Souffle::Http])
      end.to_app

      Rack::Handler.get(:thin).run(@app, rack_options)
    end
  end

  # Starts a single instance of the provisioner.
  def run_instance
    Souffle::Log.info "Single instance runs are not currently implemented..."
    # system = Souffle::System.from_hash(data)
    # provider = Souffle::Provider.plugin(system.try_opt(:provider)).new
    # system_tag = provider.create_system(system)
  end
  
end
