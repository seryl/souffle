module Souffle
  # A system description with nodes and the statemachine to manage them.
  class System
    attr_reader :nodes, :root

    state_machine :state, :initial => :uninitialized do
    end

    def initialize(root=nil)
      super() # NOTE: This is here to initialize state_machine.
    end

    # Adds the root node to the system.
    # 
    # @param [ Souffle::Node ] node The node to become to root node.
    def root=(node)
      @root = node
    end

    # Adds a node to the system tree.
    # 
    # @param [ Souffle::Node ] node The node to add into the tree.
    def add(node)
    end

  end
end
