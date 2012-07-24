module Souffle
  # A system description with nodes and the statemachine to manage them.
  class System
    attr_reader :nodes, :provider

    state_machine :state, :initial => :uninitialized do
      before_transition :uninitialized => any - :uninitialized,
        :do => :initialize_provider

      around_transition do |system, transition, block|
        start = Time.now
        block.call
        system.time_used += Time.now - start
      end
    end

    # Creates a new souffle system, defaulting to using Vagrant as a provider.
    # 
    # @param [ String ] provider The provider to use for the given system.
    def initialize(provider="Vagrant")
      initialize_provider(provider)
      @nodes = []
      super() # NOTE: This is here to initialize state_machine.
    end

    # Sets up the given provider to be used for the creation of the system.
    # 
    # @param [ String ] provider The provider to use for system creation.
    def initialize_provider(provider)
      @provider = Souffle::Provider.const_get(provider.to_sym).new
    rescue
      raise Souffle::Exceptions::InvalidProvider,
        "The provider Souffle::Provider::#{provider} does not exist."
    end

    # Proxy to the provider setup routine.
    def setup_provider
      @provider.setup
    end

    # Adds a node to the system tree.
    # 
    # @param [ Souffle::Node ] node The node to add into the tree.
    def add(node)
      @nodes << node
    end

    # Checks node dependencies and rebalances them accordingly.
    # 
    # If a node has no dependencies, it's a root node!
    # If a node has depdendencies, setup the node's parents.
    def rebalance_nodes
      clear_node_heirarchy
      dependent_nodes.each { |n| setup_node_parents(n) }
    end

    # Clears all parents and children from nodes to prepare to rebalancing.
    def clear_node_heirarchy
      @nodes.each { |n| n.parents = []; n.children = [] }
    end

    # Finds all of a nodes parent dependencies and setup the parents.
    # 
    # @param [ Souffle::Node ] node The node to check and configure.
    def setup_node_parents(node)
      optimal_deps = optimized_node_dependencies(node)
      optimal_deps.each { |node_dep| node_dep.add_child(node) }
    end

    # Gets all of the node dependencies on the system.
    # 
    # @param [ Souffle::Node ] node The node to retrieve dependencies for.
    # 
    # @return [ Array ] The tuple of [ node, dependency_list ] for the node.
    def node_dependencies_on_system(node)
      node_dependencies = []
      nodes_except(node).each do |n|
        is_dependant, dep_list = node.depends_on?(n)
        node_dependencies << [n, dep_list] if is_dependant
      end
      node_dependencies
    end

    # The optimized the node dependencies for the system.
    # 
    # @param [ Souffle::Node ] node The node that you want to optimize.
    def optimized_node_dependencies(node)
      node_dependencies_on_system(node).inject([]) do |res, d|
        res << d.first
      end
    end

    # Returns the list of all nodes except the given node.
    # 
    # @return [ Array ] The list of all nodes except the given node.
    def nodes_except(node)
      @nodes.select { |n| n != node }
    end

    # Returns the list of all root nodes.
    # 
    # @note We use dependencies here to validate whether a node is root here
    # because the parents are only determined after a rebalance is run.
    # 
    # @return [ Array ] The list of all root nodes. (Nodes without parents).
    def roots
      @nodes.select { |n| n.dependencies.empty? }
    end

    # Returns the list of all dependent nodes.
    # 
    # @return [ Array ] The list of all dependant nodes.
    def dependent_nodes
      @nodes.select { |n| n.dependencies.any? }
    end

  end
end
