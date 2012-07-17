module Souffle
  # The souffle orchestrator and management daemon.
  class Server

    # The configuration object.
    attr_accessor :config

    # Creates a new souffle orchestrator node.
    #
    # @param [ String ] config The configuration JSON.
    def initialize(config)
      Souffle::Config.from_file(config)
    end

    # Runs the orchestrator.
    def run
    end
    
  end
end
