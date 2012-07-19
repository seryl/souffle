require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Souffle::System" do
  before(:each) do
    @system = Souffle::System.new
  end

  after(:each) do
    @system = nil
  end

  it "should be able to describe a system" do
  end

  it "should have an initial state of `:uninitialized`" do
    @system.state_name.should eql(:uninitialized)
  end
end
