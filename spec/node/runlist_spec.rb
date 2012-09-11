require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Souffle::Node::RunList" do
  it "should be able to add a runlist item onto the runlist" do
    rl = Souffle::Node::RunList.new
    rl << "role[dns_server]"
    rl << "recipe[chef_server::rubygems_install]"
  end

  it "should raise an error when an invalid runlist item is added" do
    rl = Souffle::Node::RunList.new
    lambda { rl << "fsjklfds" }.should raise_error
  end

  it "should be able to present itself in a hash format" do
    rl = Souffle::Node::RunList.new
    rl << "role[dns_server]"
    rl << "recipe[chef_server::rubygems_install]"

    rl_hash = [ "role[dns_server]", "recipe[chef_server::rubygems_install]" ]

    rl.to_hash.should eql(rl_hash)
  end
end
