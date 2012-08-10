require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Souffle::Provider" do
  # before(:each) do
  #   @provider = Souffle::Provider.new
  # end

  # after(:each) do
  #   @provider = nil
  # end

  it "should raise errors on non-overridden setup" do
    @provider = Souffle::Provider.new
    # lambda { @provider.setup }.should raise_error
  end

  # it "should raise errors on non-overridden name" do
  #   lambda { @provider.name }.should raise_error
  # end

  # it "should be able to extend a system and it's nodes with helpers" do
  #   system = Souffle::System.new
  #   node = Souffle::Node.new
  #   system.add(node)

  #   class Souffle::Provider::BestWurst < Souffle::Provider
  #     def name; "BestWurst"; end
  #   end

  #   @provider = Souffle::Provider::BestWurst.new
  #   module Souffle::Provider::Helpers::BestWurst
  #     module System
  #       def added_system; "yes_system"; end
  #     end

  #     module Node
  #       def added_node; "yes_node"; end
  #     end
  #   end
  #   @provider.add_helpers(system)

  #   system.added_system.should eql("yes_system")
  #   system.nodes.first.added_node.should eql("yes_node")
  #   Souffle::Provider.send(:remove_const, :BestWurst)
  #   Souffle::Provider::Helpers.send(:remove_const, :BestWurst)
  # end

  # it "should raise errors on non-overridden create_system" do
  #   n = Souffle::Node.new
  #   lambda { @provider.create_system(n) }.should raise_error
  # end

  # it "should raise errors on non-overridden create_node" do
  #   n = Souffle::Node.new
  #   lambda { @provider.create_node(n) }.should raise_error
  # end

  # it "should raise errors on non-overridden create_raid" do
  #   lambda { @provider.create_raid }.should raise_error
  # end
end
