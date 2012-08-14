require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Souffle::Provisioner" do
  include Helpers
  
  before(:each) do
    get_config
    Souffle::Config[:provider] = "Vagrant"
    @provisioner = Souffle::Provisioner.new
  end

  after(:each) do
    @provisioner = nil
  end

  it "should be able to initialize a Vagrant provider" do
    @provisioner.provider.name.should eql("Vagrant")
  end

  it "should be raise an error on an invalid provider" do
    Souffle::Config[:provider] = "CompletelyInvalidProvider"
    d = lambda { Souffle::Provisioner.new }
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
  end

  it "should be able to setup an AWS provider" do
    Souffle::Config[:provider] = "AWS"
    @provisioner = Souffle::Provisioner.new
  end

  it "raises an InvalidProvider error when the provider doesn't exist" do
    Souffle::Config[:provider] = "UnholyProviderOfBadness"
    d = lambda { Souffle::Provisioner.new }
    d.should raise_error
  end
end
