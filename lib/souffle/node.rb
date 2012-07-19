module Souffle
  class Node; end
end

require 'souffle/node/runlist_item'
require 'souffle/node/runlist'

module Souffle
  # A node object that's part of a given system.
  class Node
    attr_accessor :dependencies, :run_list, :parent
    attr_reader :children

    state_machine :state, :initial => :uninitialized do
    end

    # Creates a new souffle node with bare dependencies and run_list.
    def initialize
      @dependencies = Souffle::Node::RunList.new
      @run_list = Souffle::Node::RunList.new
      @parent = nil
      @children = []
      super() # NOTE: This is here to initialize state_machine.
    end

    # Check whether or not a given node depends on another node.
    # 
    # @param [ Souffle::Node ] node Check to see whether this node depends
    # 
    # @return [ true,false ] Whether or not this node depends on the given.
    def depends_on?(node)
      @dependencies.each { |d| return true if node.run_list.include? d }
      false
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
      node.parent = self
      @children.push(node)
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

  end
end
