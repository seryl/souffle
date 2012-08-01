require 'souffle/provider'
require 'right_aws'

# The AWS souffle provider.
class Souffle::Provider::AWS < Souffle::Provider
  attr_reader :access_key, :access_secret

  # Setup the internal AWS configuration and object.
  def setup
    @access_key    = Souffle::Config[:aws_access_key]
    @access_secret = Souffle::Config[:aws_access_secret]

    @ec2 = RightAws::Ec2.new(
      @access_key, @access_secret,
      :region => Souffle::Config[:aws_region],
      :logger => Souffle::Log.logger)
  end
  
  # The name of the given provider.
  def name; "AWS"; end

  # Creates a system using aws as the provider.
  # 
  # @param [ Souffle::System ] system The system to instantiate.
  def create_system(system)
    if using_vpc? and vpc_setup?
    end
  end

  # Takes a list of node definitions and begins the provisioning process.
  # 
  # @param [ Array ] nodes The list of nodes to instantiate.
  def create_nodes(nodes)
  end

  # Takes a list of nodes an stops the instances.
  # 
  # @param [ Array ] nodes The list of nodes to stop.
  def stop_node(nodes)
  end

  # Creates a raid array with the given requirements.
  # 
  # @param [ Souffle::Node ] node The node create the raid for.
  def create_raid(node)
  end

  # Creates ebs volumes for the given node.
  # 
  # @param [ Souffle::Node ] node The node to create ebs volumes for.
  def create_ebs(node)
  end

  # Whether or not to use a vpc instance and subnet for provisioning.
  # 
  # @return [ true,false ] Whether to use a vpc instance and specific subnet.
  def using_vpc?
    !!Souffle::Config[:aws_vpc_id] and
    !!Souffle::Config[:aws_subnet_id]
  end

  # Checks whether or not the vpc and subnet are setup proeprly.
  # 
  # @return [ true,false ] Whether or not the vpc is setup.
  def vpc_setup?
    vpc_exists? and subnet_exists?
  end

  # Checks whether or not the vpc currently exists.
  # 
  # @return [ true,false ] Whether or not the vpc exists.
  def vpc_exists?
    @ec2.describe_vpcs({:filters =>
      { 'vpc-id' => Souffle::Config[:aws_vpc_id] } }).any?
  end

  # Checks whether or not the subnet currently exists.
  # 
  # @return [ true,false ] Whether or not the subnet exists.
  def subnet_exists?
    @ec2.describe_subnets({:filters =>
      { 'subnet-id' => Souffle::Config[:aws_subnet_id] } }).any?
  end
end
