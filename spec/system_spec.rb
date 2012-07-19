require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Souffle::System" do
  before(:each) do
    @system = Souffle::System.new
  end

  after(:each) do
    @system = nil
  end

  it "should be able to setup a Vagrant provider" do
    @system.provider.name.should eql("Vagrant")
  end

  it "should be able to setup an AWS provider" do
    @system = Souffle::System.new("AWS")
    @system.provider.name.should eql("AWS")
  end

  it "should be able to add a root node" do
    node = Souffle::Node.new
    @system.root = node
    @system.root.should eql(node)
  end

  it "should have an initial state of `:uninitialized`" do
    @system.state_name.should eql(:uninitialized)
  end
end
