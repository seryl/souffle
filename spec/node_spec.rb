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
  end

  it "should fail on invalid setup dependencies" do
  end
end
