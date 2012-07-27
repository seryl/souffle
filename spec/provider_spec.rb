require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Souffle::Provider" do
  before(:each) do
    @provider = Souffle::Provider.new
  end

  after(:each) do
    @provider = nil
  end

  it "should raise errors on non-overridden setup" do
    lambda { @provider.setup }.should raise_error
  end

  it "should raise errors on non-overridden name" do
    lambda { @provider.name }.should raise_error
  end

  it "should raise errors on non-overridden create_system" do
    n = Souffle::Node.new
    lambda { @provider.create_system(n) }.should raise_error
  end

  it "should raise errors on non-overridden create_node" do
    n = Souffle::Node.new
    lambda { @provider.create_node(n) }.should raise_error
  end

  it "should raise errors on non-overridden create_raid" do
    lambda { @provider.create_raid }.should raise_error
  end
end
