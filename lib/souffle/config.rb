module Souffle
  # The configuration object for the souffle server.
  class Config

    # Loads the given config json into the configuration object.
    #
    # @param [ String ] config The configuration json.
    def initialize(config)
      parser = Yajl::Parser.new
      @config = parser.parse(config)
    end

    # Return the configuration object requested or nil.
    #
    # @param [ String ] key The configuration key to request.
    #
    # @return [ String,Integer,true,false,nil ] The config key.
    def [] key
      @config[key.to_s]
    end

    # Sets the configuration object key.
    #
    # @param [ String,Symbol ] key The configuration key to set
    def []=(key, value)
      @config[key.to_s] = value
    end

    # The configuration object in string format.
    #
    # @return [ String ] The configuration object in string format.
    def to_s
      @config.to_s
    end

    # Return the configuration keys from the config json.
    #
    # @return [ Array ] The list of keys in the config.
    def keys
      @config.keys
    end
  end
end
