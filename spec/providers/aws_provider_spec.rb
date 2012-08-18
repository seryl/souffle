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
end

describe "Souffle::Provider::AWS (live)", :live => true do
  include Helpers
  
  before(:each) do
    get_config
    @provider = Souffle::Provider::AWS.new
  end

  after(:each) do
    @provider = nil
  end

  it "should be able to launch and provision an entire system" do
    EM.run do
      system = Souffle::System.new

      masternode = Souffle::Node.new
      masternode.name = "MasterNode"
      masternode.options[:aws_ebs_size] = 1
      masternode.options[:volume_count] = 2

      child_node1 = Souffle::Node.new
      child_node1.name = "child node 1"
      child_node1.options[:aws_ebs_size] = 2
      child_node1.options[:volume_count] = 2

      child_node2 = Souffle::Node.new
      child_node2.name = "child node 2"
      child_node2.options[:aws_ebs_size] = 3
      child_node2.options[:volume_count] = 2

      system.add(masternode)
      system.add(child_node1)
      system.add(child_node2)
      @provider.create_system(system)

      EM::Timer.new(200) do
        EM.stop
      end
    end
  end
end
