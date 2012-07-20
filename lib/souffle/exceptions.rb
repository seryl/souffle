module Souffle
  # Souffle specific exceptions; intended for debugging purposes.
  class Exceptions
    
    # Application level error.
    class Application < RuntimeError; end
    # Provider level error.
    class Provider < RuntimeError; end

    # Runlist Name cannot be nil or empty and must be a word [A-Za-z0-9_:].
    class InvalidRunlistName < RuntimeError; end
    # Runlist Type cannot be nil or empty and must be one of (role|recipe).
    class InvalidRunlistType < RuntimeError; end

    # Node children must respond to dependencies and run_list.
    class InvalidChild < RuntimeError; end

    # The provider must exist in souffle/providers.
    class InvalidProvider < RuntimeError; end

    # Root node cannot be nil and must be declared before adding new nodes.
    class RootNodeIsNil < RuntimeError; end
  end
end
