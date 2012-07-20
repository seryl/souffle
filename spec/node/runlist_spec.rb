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
end
