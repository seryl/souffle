module Souffle
  # The souffle orchestrator and management daemon.
  class Orchestrator

    # The configuration object.
    attr_accessor :config

    # Creates a new souffle orchestrator node.
    #
    # @param [ String ] config The configuration JSON.
    def initialize(config)
      @config = Souffle::Config.new(config)
    end

    # Runs the orchestrator.
    def run
    end
    
  end
end
