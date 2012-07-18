require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Souffle::Node" do
  before(:each) do
    @node = Souffle::Node.new
  end

  after(:each) do
    @node = nil
  end

  it "should be able to describe a single node" do
  end

  it "should be able to setup dependencies" do
    @node.dependencies << "role[chef_server]"
    @node.dependencies.should eql(["role[chef_server]"])
  end

  it "should fail on improper dependencies" do
  end

  it "should be able to setup the run_list" do
    @node.run_list << "example_role"
    @node.run_list.should eql(["example_role"])
  end

  it "should fail on improper run_list" do
  end
end
