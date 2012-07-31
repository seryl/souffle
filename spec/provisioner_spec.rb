require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Souffle::Provisioner" do
  before(:each) do
    @provisioner = Souffle::Provisioner.new
  end

  after(:each) do
    @provisioner = nil
  end

  it "should be able to initialize a Vagrant provider" do
    @provisioner.provider.name.should eql("Vagrant")
  end

  it "should be raise an error on an invalid provider" do
    d = lambda { Souffle::Provisioner.new("CompletelyInvalidProvider") }
    d.should raise_error
  end

  it "should be able to initialize an AWS provider" do
    Souffle::Config[:provider] = "AWS"
    @provisioner = Souffle::Provisioner.new
    @provisioner.provider.name.should eql("AWS")
  end

  it "should be able to setup an Vagrant provider" do
    Souffle::Config[:provider] = "Vagrant"
    @provisioner = Souffle::Provisioner.new
    @provisioner.setup_provider
  end

  it "should be able to setup an AWS provider" do
    Souffle::Config[:provider] = "AWS"
    @provisioner = Souffle::Provisioner.new
    @provisioner.setup_provider
  end

  it "raises an InvalidProvider error when the provider doesn't exist" do
    d = lambda { Souffle::Provisioner.new("UnholyProviderOfBadness") }
    d.should raise_error
  end

  it "should be able to create an entire system from a hash" do
    
  end
end
