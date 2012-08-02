require 'souffle/provider'
require 'right_aws'
require 'securerandom'

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

  # Generates a prefixed unique tag.
  # 
  # @param [ String ] tag_prefix The tag prefix to use.
  # 
  # @return [ String ] The unique tag with prefix.
  def generate_tag(tag_prefix="souffle")
    "#{tag_prefix}-#{SecureRandom.hex(6)}"
  end

  # Creates a system using aws as the provider.
  # 
  # @param [ Souffle::System ] system The system to instantiate.
  # @param [ String ] tag_prefix The tag prefix to use for the system.
  def create_system(system, tag_prefix="souffle")
    system.options[:tag] = generate_tag(tag_prefix)
    if using_vpc? and vpc_setup?
    end
  end

  # Takes a list of nodes and returns the list of their aws instance_ids.
  # 
  # @param [ Array ] nodes The list of nodes to get instance_id's from.
  def instance_id_list(nodes)
    node_id_list = Array.new
    Array(nodes).each { |n| node_id_list << n.options[:aws_instance_id] }
    node_id_list
  end

  # Takes a node definition and begins the provisioning process.
  # 
  # @param [ Souffle::Node ] nodes The node to instantiate.
  # @param [ String ] tag The tag to use for the node.
  def create_node(node, tag="")
    options = Hash.new
    options[:min_count] = 1
    options[:max_count] = 1

    ebs_info = create_ebs(node)
    @ec2.launch_instances(
      node[:options].fetch(:aws_image_id, Souffle::Config[:aws_image_id]),
      options)
  end

  # Takes a list of nodes an stops the instances.
  # 
  # @param [ Souffle::Node, Array ] nodes The list of nodes to stop.
  def stop_nodes(nodes)
    @ec2.stop_instances(instance_id_list(nodes))
  end

  # Stops all nodes in a given system.
  # 
  # @param [ Souffle::System ] system The system to stop.
  def stop_system(system)
    stop_nodes(system.nodes)
  end

  # Takes a list of nodes and kills them. (Haha)
  # 
  # @param [ Souffle::Node ] nodes The list of nodes to terminate.
  def kill_nodes(nodes)
    @ec2.terminate_instances(instance_id_list(nodes))
  end

  # Creates a raid array with the given requirements.
  # 
  # @param [ Souffle::Node ] node The node to the raid for.
  def create_raid(node)
  end

  # Creates ebs volumes for the given node.
  # 
  # @param [ Souffle::Node ] node The node to create ebs volumes for.
  # 
  # @param [ Array ] The list of created ebs volumes.
  def create_ebs(node)
    volumes = Array.new
    Array(node[:options][:volumes]).each do |vol_list, volume|
      volumes << @ec2.create_volume(
        node[:options].fetch(:aws_snapshot_id, ""),
        node[:options][:aws_ebs_size],
        node[:options][:aws_availability_zone] )
    end
    volumes
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
