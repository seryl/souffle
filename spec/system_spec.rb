require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Souffle::System" do
  before(:each) do
    @system = Souffle::System.new
  end

  after(:each) do
    @system = nil
  end

  it "should be able to initialize a Vagrant provider" do
    @system.provider.name.should eql("Vagrant")
  end

  it "should be able to initialize an AWS provider" do
    @system = Souffle::System.new("AWS")
    @system.provider.name.should eql("AWS")
  end

  it "should be able to setup an Vagrant provider" do
    @system = Souffle::System.new("Vagrant")
    @system.setup_provider
  end

  it "should be able to setup an AWS provider" do
    @system = Souffle::System.new("AWS")
    @system.setup_provider
  end

  it "should raise an InvalidProvider error when the provider doesn't exist" do
    d = lambda { @system = Souffle::System.new("UnholyProviderOfBadness") }
    d.should raise_error
  end

  it "should be able to add a root node" do
    node = Souffle::Node.new
    @system.root = node
    @system.root.should eql(node)
  end

  it "should raise an error when added a node with a nil root node" do
    node = Souffle::Node.new
    lambda { @system.add(node) }.should raise_error
  end

  it "should be able to add a child node to the root node" do
    node  = Souffle::Node.new
    node2 = Souffle::Node.new
    @system.root = node
    lambda do
      @system.add(node2)
      @system.rebalance_nodes
    end.should_not raise_error
    @system.root.children.include?(node2).should eql(true)
  end

  it "should be able to clear all nodes parent and child heirarchy" do
    node  = Souffle::Node.new
    node2 = Souffle::Node.new
    @system.root = node
    @system.root.add_child(node2)
    @system.add(node2)

    root_node  = @system.root
    child_node = @system.nodes.first

    root_node.children.include?(child_node).should eql(true)
    child_node.parents.include?(root_node).should eql(true)
    @system.clear_node_heirarchy
    root_node.children.should eql([])
    child_node.parents.should eql([])
  end

  it "should be able to get the node dependencies on a system" do
    root_node = Souffle::Node.new

    node  = Souffle::Node.new
    node2 = Souffle::Node.new
    node3 = Souffle::Node.new

    node.dependencies << "role[example_role]"
    node.dependencies << "recipe[the_best_one]"

    node2.run_list << "role[example_role]"
    node3.run_list << "recipe[the_best_one]"

    @system.root = root_node
    @system.add(node)
    @system.add(node2)
    @system.add(node3)

    @system.get_node_dependencies_on_system(node).should eql(
      [ [node2, [Souffle::Node::RunListItem.new("role[example_role]")] ],
        [node3, [Souffle::Node::RunListItem.new("recipe[the_best_one]")] ],
      ]
    )
  end

  it "should be able to rebalance a system of nodes"

  it "should have an initial state of `:uninitialized`" do
    @system.state_name.should eql(:uninitialized)
  end
end
