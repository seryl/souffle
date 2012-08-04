# AWS helper modules.
module Souffle::Provider::Helpers::AWS

  # AWS system helpers.
  module System

    # Returns the current tag for the system.
    # 
    # @return [ String ] The current tag for the system.
    def tag
      options[:tag]
    end

    # Sets the current tag for the system.
    # 
    # @param [ String ] new_tag The new tag for the system.
    def tag=(new_tag)
      options[:tag] = new_tag
    end
  end

  # AWS node helpers.
  module Node

    # Returns the list of volumes for a given node.
    # 
    # @return [ Array ] The list of volumes for a given node.
    def volumes
      options[:volumes] ||= []
      options[:volumes]
    end
  end
  
end
