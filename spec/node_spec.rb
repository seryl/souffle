require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Souffle::Node" do
  before(:each) do
    @node = Souffle::Node.new
  end

  after(:each) do
    @node = nil
  end

  it "should be able to setup dependencies" do
    @node.dependencies << "recipe[chef_server]"
    item = @node.dependencies.first
    item.type.should eql("recipe")
    item.name.should eql("chef_server")
  end

  it "should be able to setup the run_list" do
    @node.run_list << "role[example_role]"
    item = @node.run_list.first
    item.type.should eql("role")
    item.name.should eql("example_role")
  end

  it "should fail on improper run_list type" do
    lambda { @node.run_list<<("b0rken[role]") }.should raise_error
  end

  it "should fail on improper run_list name" do
    lambda { @node.run_list << "role[GT***]}" }.should raise_error
  end

  it "should be able to describe a single node" do
    rlist = [
      "recipe[chef_server::rubygems_install]",
      "role[dns_server]" ]
    rlist.each { |rl| @node.run_list << rl }
    @node.run_list.each do |rl_item|
      rlist.include?(rl_item.to_s).should eql(true)
    end
  end

  it "should be able to test whether or not a node depends on another" do
    @node.run_list << "role[dns_server]"
    node2 = Souffle::Node.new
    node2.dependencies << "role[dns_server]"
    node2.depends_on?(@node).should eql(
      [ true, [Souffle::Node::RunListItem.new("role[dns_server]")] ]
    )
  end

  it "should not depend on another node when there are no dependencies" do
    @node.run_list << "role[dns_server]"
    node2 = Souffle::Node.new
    node2.depends_on?(@node).should eql([ false, [] ])
  end

  it "should be able to add child nodes" do
    child = Souffle::Node.new
    lambda { @node.add_child(child) }.should_not raise_error
    @node.children.should eql([child])
  end

  it "should not duplicate a child node that's added" do
    child = Souffle::Node.new
    @node.add_child(child)
    @node.add_child(child)
    @node.children.should eql([child])
  end

  it "should raise and error on adding an invalid child" do
    lambda { node.add_child([]) }.should raise_error
  end

  it "should be able to iterate across children" do
    child1 = Souffle::Node.new
    child2 = Souffle::Node.new
    @node.add_child(child1)
    @node.add_child(child2)

    children = [child1, child2]
    @node.each_child { |c| children.delete(c) }
    children.should eql([])
  end

  it "should be able to test node equality" do
    @node.dependencies << "role[awesome]"
    @node.run_list << "recipe[the_best]"
    
    node2 = Souffle::Node.new
    node2.dependencies << "role[awesome]"
    node2.run_list << "recipe[the_best]"
    @node.should eql(node2)
  end

  it "should have a depency weight of 1 with no parents" do
    @node.weight.should eql(1)
  end

  it "should have a dependency weight of at least 2 with a parent" do
    parent = Souffle::Node.new
    parent.add_child(@node)
    (@node.weight >= 2).should eql(true)
  end

  it "should have a name and be able to set it" do
    @node.name = "AwesomeName"
    @node.name.should eql("AwesomeName")
  end
end
