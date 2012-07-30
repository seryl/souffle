require 'puma'
require 'eventmachine'
require 'souffle/http'

# The souffle server and management daemon.
class Souffle::Server

  # Creates a new souffle server.
  # 
  # @param [ true,false ] serve_forever 
  def initialize(serve_forever=false)
    @serve_forever = serve_forever
  end

  # Runs the server.
  def run
    if @serve_forever
      EM.run do
        @app = Rack::Builder.new do
          use Rack::Lint
          use Rack::ShowExceptions
          run Rack::Cascade.new([Souffle::Http])
        end.to_app

        Rack::Handler.get(:puma).run(@app, rack_options)
      end
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
  
end
