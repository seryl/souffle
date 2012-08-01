module Souffle
  # A node object that's part of a given system.
  class Node; end
end

require 'souffle/node/runlist_item'
require 'souffle/node/runlist'

# A node object that's part of a given system.
class Souffle::Node
  attr_accessor :dependencies, :run_list,
    :parents, :children, :name, :options

  # Creates a new souffle node with bare dependencies and run_list.
  # 
  # @param [ Integer ] parent_multiplier The multiplier for parent nodes.
  def initialize(parent_multiplier=5)
    @dependencies = Souffle::Node::RunList.new
    @run_list = Souffle::Node::RunList.new
    @parents = []
    @children = []
    @parent_multiplier = parent_multiplier
  end

  # Check whether or not a given node depends on another node.
  # 
  # @example
  # 
  #   n1 = Souffle::Node.new
  #   n2 = Souffle::Node.new
  # 
  #   n1.run_list     << "role[dns_server]"
  #   n2.dependencies << "role[dns_server]"
  #   n2.depends_on?(n1)
  # 
  #   > [ true, [role[dns_server]] ]
  # 
  # @param [ Souffle::Node ] node Check to see whether this node depends
  # 
  # @return [ Array ] The tuple of [depends_on, dependency_list].
  def depends_on?(node)
    dependency_list = []
    @dependencies.each do |d|
      dependency_list << d if node.run_list.include? d
    end
    [dependency_list.any?, dependency_list]
  end

  # Adds a child node to the current node.
  # 
  # @param [ Souffle::Node ] node The node to add as a child.
  # 
  # @raise [ InvaidChild ] Children must have dependencies and a run_list.
  def add_child(node)
    unless node.respond_to?(:dependencies) && node.respond_to?(:run_list)
      raise Souffle::Exceptions::InvalidChild,
        "Child must act as a Souffle::Node"
    end
    unless @children.include? node
      node.parents << self
      @children.push(node)
    end
  end

  # Iterator method for children.
  # 
  # @yield [ Souffle::Node,nil ] The child node.
  def each_child
    @children.each { |child| yield child }
  end

  # Equality comparator for nodes.
  # 
  # @param [ Souffle::Node ] other The node to compare against.
  def eql?(other)
    @dependencies == other.dependencies && @run_list == other.run_list
  end

  # The dependency weight of a given node.
  # 
  # @return [ Integer ] The relative weight of a node used for balancing.
  def weight
    @parents.inject(1) { |res, p| res + p.weight * @parent_multiplier }
  end
end
