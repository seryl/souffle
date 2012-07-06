module Souffle
  # Worker daemon for handling requests from the orchestrator.
  class Worker

    # The configuration object.
    attr_accessor :config

    # Creates a new souffle worker node.
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
