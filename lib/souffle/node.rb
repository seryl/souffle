module Souffle
  class Node; end
end

require 'souffle/node/runlist_item'
require 'souffle/node/runlist'

module Souffle
  # A node object that's part of a given system.
  class Node
    attr_accessor :dependencies, :run_list

    # state_machine :initial => :nonexistant do
    #   after_transition any => :creating, :do => :create
    #   after_transition any => :

    #   event :created do
    #     transition :creating => :configuring
    #   end

    #   event :configuring do
    #     transition :

    #   event :started do
    #     transition :starting => :initializing
    # end

    # Creates a new souffle node with bare dependencies and run_list.
    def initialize
      @dependencies = Souffle::Node::RunList.new
      @run_list = Souffle::Node::RunList.new
    end

  end
end
