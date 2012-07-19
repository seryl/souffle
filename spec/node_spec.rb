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
    @node.run_list << "recipe[chef_server::rubygems_install]"
    @node.run_list << "role[dns_server]"
  end

  it "should be able to test whether or not a node depends on another" do
    @node.run_list << "role[dns_server]"
    @node2 = Souffle::Node.new
    @node2.dependencies << "role[dns_server]"
    @node2.depends_on?(@node).should eql(true)
    @node2 = nil
  end

  it "should not depend on another node when there are no dependencies" do
    @node.run_list << "role[dns_server]"
    @node2 = Souffle::Node.new
    @node2.depends_on?(@node).should eql(false)
    @node2 = nil
  end

  it "should be able to add child nodes" do
    @child = Souffle::Node.new
    lambda { @node.add_child(@child) }.should_not raise_error
    @node.children.should eql([@child])
    @child = nil
  end

  it "should raise and error on adding an invalid child" do
    @child = []
    lambda { @node.add_child(@child) }.should raise_error
    @child = nil
  end
end
