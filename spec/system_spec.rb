require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'set'

describe "Souffle::System" do
  before(:each) do
    @system = Souffle::System.new
  end

  after(:each) do
    @system = nil
  end

  it "should be able to find all of the nodes with no parents" do
    node1 = Souffle::Node.new
    node2 = Souffle::Node.new
    node3 = Souffle::Node.new
    node4 = Souffle::Node.new

    node1.dependencies << "role[awesomeone]"
    node2.dependencies << "recipe[bleh]"

    @system.add(node1)
    @system.add(node2)
    @system.add(node3)
    @system.add(node4)

    @system.roots.to_set.should eql(Set.new([node3, node4]))
  end

  it "should be able to add a root node" do
    node = Souffle::Node.new
    @system.add(node)
    @system.roots.should eql([node])
  end

  it "should be able to determine dependant nodes" do
    node1 = Souffle::Node.new
    node2 = Souffle::Node.new

    node1.run_list     << "role[some_silly_role]"
    node2.dependencies << "role[some_silly_role]"

    @system.add(node1)
    @system.add(node2)

    @system.rebalance_nodes
    @system.dependent_nodes.should eql([node2])
  end

  it "should be able to clear all nodes parent and child heirarchy" do
    node1  = Souffle::Node.new
    node2 = Souffle::Node.new

    node1.run_list     << "role[some_silly_role]"
    node2.dependencies << "role[some_silly_role]"

    @system.add(node1)
    @system.add(node2)
    @system.rebalance_nodes

    node1.children.include?(node2).should eql(true)
    node2.parents.include?(node1).should eql(true)

    @system.clear_node_heirarchy
    node1.children.should eql([])
    node2.parents.should eql([])
  end

  it "should be able to get the node dependencies on a system" do
    node1  = Souffle::Node.new
    node2 = Souffle::Node.new
    node3 = Souffle::Node.new

    node1.dependencies << "role[example_role]"
    node1.dependencies << "recipe[the_best_one]"

    node2.run_list << "role[example_role]"
    node3.run_list << "recipe[the_best_one]"

    @system.add(node1)
    @system.add(node2)
    @system.add(node3)

    @system.dependencies_on_system(node1).should eql(
      [ [node2, [Souffle::Node::RunListItem.new("role[example_role]")] ],
        [node3, [Souffle::Node::RunListItem.new("recipe[the_best_one]")] ]
      ] )
  end

  it "should be able to optimize a rebalanced system of nodes" do
    target = Souffle::Node.new
    heavy1 = Souffle::Node.new
    heavy2 = Souffle::Node.new
    root_node = Souffle::Node.new
    light_node = Souffle::Node.new

    target.dependencies << "role[example_role]"
    target.dependencies << "recipe[the_best_one]"

    heavy1.run_list << "role[example_role]"
    heavy2.run_list << "recipe[the_best_one]"
    heavy1.dependencies << "recipe[heavy]"
    heavy2.dependencies << "recipe[heavy]"

    root_node.run_list << "recipe[heavy]"

    light_node.run_list << "role[example_role]"
    light_node.run_list << "recipe[the_best_one]"

    @system.add(target)
    @system.add(heavy1)
    @system.add(heavy2)
    @system.add(root_node)
    @system.add(light_node)

    @system.rebalance_nodes
    @system.optimized_node_dependencies(target).should eql([light_node])
  end

    it "should have children nodes that can identify the system" do
    target = Souffle::Node.new
    heavy1 = Souffle::Node.new
    heavy2 = Souffle::Node.new
    root_node = Souffle::Node.new
    light_node = Souffle::Node.new

    target.dependencies << "role[example_role]"
    target.dependencies << "recipe[the_best_one]"

    heavy1.run_list << "role[example_role]"
    heavy2.run_list << "recipe[the_best_one]"
    heavy1.dependencies << "recipe[heavy]"
    heavy2.dependencies << "recipe[heavy]"

    root_node.run_list << "recipe[heavy]"

    light_node.run_list << "role[example_role]"
    light_node.run_list << "recipe[the_best_one]"

    @system.add(target)
    @system.add(heavy1)
    @system.add(heavy2)
    @system.add(root_node)
    @system.add(light_node)

    @system.rebalance_nodes
    @system.nodes.each { |n| n.system.should eql(@system) }
  end

  it "should raise an exception on an incorrect system hash" do
    sys = {}
    lambda { Souffle::System.from_hash(sys) }.should raise_error
  end

  it "should be able to get system options with try_opt" do
    @system.options[:example_opt] = "sporkmejohhny"
    @system.try_opt(:example_opt).should eql("sporkmejohhny")
  end

  it "should pass-thru to config options when they do not exist" do
    Souffle::Config[:example_passthru] = "blehk"
    @system.try_opt(:example_passthru).should eql("blehk")
    Souffle::Config.configuration.delete(:example_passthru)
  end

  it "should let child nodes get system opts with pass-thru" do
    node = Souffle::Node.new
    @system.add(node)
    @system.options[:example_opt] = "sporkmejohhny"
    @system.nodes.first.try_opt(:example_opt).should eql("sporkmejohhny")
  end

  it "should pass-thru to config options when they do not exist" do
    Souffle::Config[:example_passthru] = "blehk"
    @system.try_opt(:example_passthru).should eql("blehk")
    Souffle::Config.configuration.delete(:example_passthru)
  end

  it "should be able to generate a system from a hash" do
    sys = {
      :nodes => [
        { :name => "parent_node",
          :run_list => ["role[somerole]"],
          :dependencies => [] },
        { :name => "lone_node",
          :run_list => ["role[bestone]"],
          :dependencies => [] },
        { :name => "child_node",
          :run_list => ["recipe[base]"],
          :dependencies => ["role[somerole]"] }
      ]
    }

    new_sys = Souffle::System.from_hash(sys)
    new_sys.rebalance_nodes

    parent = new_sys.nodes.select { |n| n.name == "parent_node" }.first
    parent.children.first.name.should eql("child_node")
    new_sys.roots.size.should eql(2)
    new_sys.dependent_nodes.size.should eql(1)
  end

  it "should be able to generate system options and merge from a hash" do
    sys = {
      :options => { :type => "chef" },
      :nodes => [
        { :name => "parent_node",
          :options => { :type => "chef-solo" },
          :run_list => ["role[somerole]"],
          :dependencies => [] },
        { :name => "lone_node",
          :run_list => ["role[bestone]"],
          :dependencies => [] },
        { :name => "child_node",
          :run_list => ["recipe[base]"],
          :dependencies => ["role[somerole]"] }
      ]
    }

    new_sys = Souffle::System.from_hash(sys)
    new_sys.rebalance_nodes

    parent = new_sys.nodes.select { |n| n.name == "parent_node" }.first
    parent.children.first.name.should eql("child_node")
    parent.options.should eql({ :attributes => {}, :type => "chef-solo" })
    parent.children.first.options.should eql({ :attributes => {} })
    
    new_sys.roots.size.should eql(2)
    new_sys.dependent_nodes.size.should eql(1)
  end

  it "should have the same system in a hash format as it does in dsl" do
    sys = {
      :nodes => [
        { :name => "MasterNode",
          :run_list => [  "recipe[gem]",
                          "recipe[git]" ],
          :options  => {
            :gem => { :source => "http://gem.test.com" },
            :aws_ebs_size => 10,
            :volume_count => 2
          }
        }
      ]
    }

    sys2 = Souffle::System.new
    masternode = Souffle::Node.new
    masternode.name = "MasterNode"
    masternode.run_list << "recipe[gem]"
    masternode.run_list << "recipe[git]"
    masternode.options[:gem] = { :source => "http://gem.test.com" }
    masternode.options[:aws_ebs_size] = 10
    masternode.options[:volume_count] = 2
    sys2.add(masternode)

    new_sys = Souffle::System.from_hash(sys)

    parent = new_sys.nodes.select { |n| n.name == "MasterNode" }.first
    parent.run_list.should eql(masternode.run_list)
    parent.options.should eql(masternode.options)
  end

  it "should be able to generate a system hash from a working system" do
    sys = {
      :options => { :type => "chef" },
      :nodes => [
        { :name => "parent_node",
          :options => { :type => "chef-solo", :attributes => {} },
          :run_list => ["role[somerole]"],
          :dependencies => [],
          :provisioner => nil },
        { :name => "lone_node",
          :options => { :attributes => {} },
          :run_list => ["role[bestone]"],
          :dependencies => [],
          :provisioner => nil },
        { :name => "child_node",
          :options => { :attributes => {} },
          :run_list => ["recipe[base]"],
          :dependencies => ["role[somerole]"],
          :provisioner => nil }
      ]
    }

    new_sys = Souffle::System.from_hash(sys)
    new_hash = new_sys.to_hash
    new_hash[:options].should eql(sys[:options])
    new_hash[:nodes].each { |n| sys[:nodes].include?(n).should eql(true) }
  end
end
