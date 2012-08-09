require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Souffle::Provider::AWS" do
  include Helpers
  
  before(:each) do
    get_config
    @provider = Souffle::Provider::AWS.new
  end

  after(:each) do
    @provider = nil
  end

  # Note:
  #   All of the AWS routines will only run if you are provided a
  #   valid aws_access_key and aws_access_secret.

  it "should be able to see whether the configuration has vpc setup" do
    aws_vpc_id = "vpc-124ae13"
    aws_subnet_id = "subnet-24f6a87f"
    node = Souffle::Node.new

    Souffle::Config[:aws_vpc_id] = aws_vpc_id
    Souffle::Config[:aws_subnet_id] = aws_subnet_id

    @provider.using_vpc?(node).should eql(true)
  end

  it "should not use vpc when the keys are missing" do
    aws_vpc_id = "vpc-124ae13"
    aws_subnet_id = "subnet-24f6a87f"
    node = Souffle::Node.new

    Souffle::Config[:aws_vpc_id] = aws_vpc_id
    Souffle::Config[:aws_subnet_id] = nil
    @provider.using_vpc?(node).should eql(false)

    Souffle::Config[:aws_vpc_id] = nil
    Souffle::Config[:aws_subnet_id] = aws_subnet_id
    @provider.using_vpc?(node).should eql(false)

    Souffle::Config[:aws_vpc_id] = nil
    Souffle::Config[:aws_subnet_id] = nil
    @provider.using_vpc?(node).should eql(false)
  end

  it "should be able to generate a unique tag" do
    tag1 = @provider.generate_tag
    tag2 = @provider.generate_tag
    tag1.should_not eql(tag2)
  end

  it "should be able to generate a unique tag with a prefix" do
    @provider.generate_tag("example").include?("example").should eql(true)
  end

  it "should return a list of instance ids for a list of nodes" do
    node1 = Souffle::Node.new
    node2 = Souffle::Node.new
    node3 = Souffle::Node.new

    node1.options[:aws_instance_id] = "1a"
    node2.options[:aws_instance_id] = "2b"
    node3.options[:aws_instance_id] = "3c"

    nodelist = [node1, node2, node3]
    @provider.instance_id_list(nodelist).should eql(["1a", "2b", "3c"])
  end

  it "should be able to launch an ebs volume" do
    @provider.setup
    system = Souffle::System.new
    node = Souffle::Node.new

    system.add(node)
    @provider.create_system(system)
    node = Souffle::Node.new
    node.name = "TheBestNameEver"
    node.options[:aws_ebs_size] = 11

    @provider.create_ebs(node)
    @provider.create_node(node, @provider.generate_tag("test"))

    sleep 20
    @provider.attach_ebs(node)

    # sleep 10
    # require 'pry'
    # binding.pry
  end

  # it "should be able to launch a node" do
  #   node = Souffle::Node.new
  #   node.name = "TheBestNameEver"
  #   node.options[:aws_ebs_size] = 11
  #   node.options[:volume_count] = 2
  #   require 'pry'

  #   @provider.setup
  #   binding.pry

  #   # @provider.create_ebs(node)
  #   # @provider.create_node(node, "example_tag")

  #   # p node
  #   # sleep 20
  #   # @provider.kill_nodes(node)
  # end
end
