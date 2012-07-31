require 'souffle/provider'
require 'right_aws'

# The AWS souffle provider.
class Souffle::Provider::AWS < Souffle::Provider
  attr_reader :access_key, :access_secret

  # Setup the internal AWS configuration and object.
  def setup
    @access_key    = Souffle::Config[:aws_access_key]
    @access_secret = Souffle::Config[:aws_access_secret]
    @ec2 = RightAws::Ec2.new(@access_key, @access_secret)
  end
  
  # The name of the given provider.
  def name; "AWS"; end

  # Creates a system using aws as the provider.
  # 
  # @param [ Souffle::System ] system The system to instantiate.
  def create_system(system)
  end

  # Takes a node definition and begins the provisioning process.
  # 
  # @param [ Souffle::Node ] node The node to instantiate.
  def create_node(node)
  end

  # Creates a raid array with the given requirements.
  def create_raid
    # @ec2.
  end

  def create_ebs

  end

  # Whether or not to use a vpc instance and subnet for provisioning.
  # 
  # @return [ true,false ] Whether to use a vpc instance and specific subnet.
  def use_vpc?
    !!Souffle::Config[:aws_vpc_id] and
    !!Souffle::Config[:aws_subnet_id]
  end
end
