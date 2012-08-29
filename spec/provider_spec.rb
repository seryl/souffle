require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Souffle::Provider::Base" do
  before(:each) do
    @provider = Souffle::Provider::Base.new
  end

  after(:each) do
    @provider = nil
  end

  it "should have Base as a default name" do
    @provider.name.should eql("Base")
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

  it "should have an ssh_key_path that matches the provider name" do
    @provider.send(:ssh_key_path).should eql(
      "/etc/souffle/ssh/#{@provider.name.downcase}")
  end

  it "should have a relative ssh key helpers" do
    base_path = "/etc/souffle/ssh/base"
    @provider.send(:ssh_key, "mykey").should eql("#{base_path}/mykey")
  end

  it "should be able to generate chef-solo json for a node." do
    node = Souffle::Node.new
    node.name = "TheBestOne"
    rlist = [ "recipe[chef_server::rubygems_install]", "role[dns_server]" ]
    rlist.each { |rl| node.run_list << rl }

    runlist = {
      "domain" => "souffle",
      "run_list" => [
        "recipe[chef_server::rubygems_install]",
        "role[dns_server]"
      ]
    }

    JSON.parse(@provider.generate_chef_json(node)).should eql(runlist)
  end
end
