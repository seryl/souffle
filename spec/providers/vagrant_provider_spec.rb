require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Souffle::Provider::Vagrant" do
  before(:each) do
    @provider = Souffle::Provider::Vagrant.new
  end

  after(:each) do
    @provider = nil
    Souffle::Config[:vagrant_dir] = "/#{ENV['HOME']}/vagrant/vms"
  end

  it "should have setup initialize the access key and secret" do
    example_vagrant_dir = "/path/so/vagrant"
    Souffle::Config[:vagrant_dir] = "/path/so/vagrant"
    @provider.setup
    @provider.vagrant_dir.should eql(example_vagrant_dir)
  end
end
