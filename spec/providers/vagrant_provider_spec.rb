require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Souffle::Provider::Vagrant" do
  include Helpers
  
  before(:each) do
    get_config
    @provider = Souffle::Provider::Vagrant.new
  end

  after(:each) do
    @provider = nil
    Souffle::Config[:vagrant_dir] = "/#{ENV['HOME']}/vagrant/vms"
  end

  it "should have setup initialize the access key and secret" do
    example_vagrant_dir = "/path/to/vagrant/vms"
    Souffle::Config[:vagrant_dir] = "/path/to/vagrant/vms"
    @provider = Souffle::Provider::Vagrant.new
    @provider.vagrant_dir.should eql(example_vagrant_dir)
  end
end
