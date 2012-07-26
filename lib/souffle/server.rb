require 'rack'
require 'thin'
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

        Rack::Handler::Thin.run(@app, {})
      end
    end
  end
  
end
