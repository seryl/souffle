require 'set'

# A system description with nodes and the statemachine to manage them.
class Souffle::System
  attr_reader :nodes
  attr_accessor :options

  # Creates a new souffle system.
  def initialize
    @nodes = []
    @options = {}
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
    optimal_deps.each { |n, node_deps| n.add_child(node) }
  end

  # Gets all of the node dependencies on the system.
  # 
  # @param [ Souffle::Node ] node The node to retrieve dependencies for.
  # 
  # @return [ Array ] The tuple of [ node, dependency_list ] for the node.
  def dependencies_on_system(node)
    node_dependencies = []
    nodes_except(node).each do |n|
      is_dependant, dep_list = node.depends_on?(n)
      node_dependencies << [n, dep_list] if is_dependant
    end
    node_dependencies
  end

  # Returns a dependency to node list mapping.
  # 
  # @return [ Hash ] The mapping of depdencies to nodes.
  def dependency_mapping(node)
    mapping = {}
    dependencies_on_system(node).each do |n, deps|
      deps.each do |dep|
        mapping[dep] ||= []; mapping[dep] << n
      end
    end
    mapping
  end

  # The optimized the node dependencies for the system.
  # 
  # @param [ Souffle::Node ] node The node that you want to optimize.
  def optimized_node_dependencies(node)
    deps = Set.new
    dependency_mapping(node).each do |dep, nodes|
      deps << nodes.sort_by { |n| n.weight }.first
    end
    deps.to_a
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

  class << self
    # Creates a new system from a given hash.
    # 
    # @param [ Hash ] system_hash The hash representation of the system.
    def from_hash(system_hash)
      guarentee_valid_hash(system_hash)
      system_hash[:options] ||= {}

      sys = Souffle::System.new
      system_hash[:nodes].each do |n|
        n[:options] ||= Hash.new
        
        node = Souffle::Node.new
        node.name = n[:name]
        Array(n[:run_list]).each { |rl| node.run_list << rl }
        Array(n[:dependencies]).each { |dep| node.dependencies << dep }
        node.options = system_hash[:options].merge(n[:options])
        sys.add(node)
      end
      sys
    end

    private

    # Guarentee that the system hash that was passed in is valid.
    # 
    # @param [ Hash ] system_hash The hash representation of the system.
    def guarentee_valid_hash(system_hash)
      if system_hash.nil? or !system_hash.has_key?(:nodes)
        raise Souffle::Exceptions::InvalidSystemHash,
          "The system hash must have a nodes key with a list of nodes."
      end
    end
  end

end
