require 'souffle/provider'
require 'souffle/provider/aws/helper'
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
    add_helpers(system)
    system.options[:tag] = generate_tag(tag_prefix)
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
  # @param [ Souffle::Node ] node The node to instantiate.
  # @param [ String ] tag The tag to use for the node.
  def create_node(node, tag)
    opts = Hash.new
    opts[:instance_type] = node.try_opt(:aws_instance_type)
    opts[:min_count] = 1
    opts[:max_count] = 1
    if using_vpc?(node)
      opts[:subnet_id] = node.try_opt(:aws_subnet_id)
      node.options[:aws_subnet_id] = node.try_opt(:aws_subnet_id)
      node.options[:aws_vpc_id] = node.try_opt(:aws_vpc_id)
    end

    instance_info = @ec2.launch_instances(
      node.try_opt(:aws_image_id), opts).first
    
    node.options[:aws_instance_id] = instance_info[:aws_instance_id]
    tag_node(node, tag)
  end

  # Tags a node and it's volumes.
  # 
  # @param [ Souffle::Node ] node The node to tag.
  # @param [ String ] tag The tag to use for the node.
  def tag_node(node, tag="")
    @ec2.create_tags(Array(node.options[:aws_instance_id]), {
      :Name => node.name,
      :souffle => tag
    })
    volume_ids = node.options[:volumes].map { |vol| vol[:aws_id] }
    @ec2.create_tags(Array(volume_ids), {
      :instance_id => node.options[:aws_instance_id],
      :souffle => tag
    })
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
  # @param [ Array ] devices The list of devices to use for the raid.
  # @param [ Fixnum ] md_device The md device number.
  # @param [ Fixnum ] chunk The chunk size in kilobytes.
  # @param [ String ] level The raid level to use.
  # options are: linear, raid0, 0, stipe, raid1, 1, mirror,
  # raid4, 4, raid5, 5, raid6, 6, multipath, mp
  def create_raid(node, devices=[], md_device=0, chunk=64, level="raid0")
    mdadm_string =  "mdadm --create /dev/md#{md_device} "
    mdadm_string << "--chunk=#{chunk} --level=#{level} "
    mdadm_string << "--raid-devices=#{devices.size} #{devices.join(' ')}"
    ssh_cmd(node) { |ssh| ssh.exec!(mdadm_string) }
  end

  # Formats a device on a given node with the provided filesystem.
  # 
  # @param [ Souffle::Node ] node The node to format a device on.
  # @param [ String ] device The device to format.
  # @param [ String ] filesystem The filesystem to use when formatting.
  def format_device(node, device, filesystem="ext4")
    ssh_cmd(node) { |ssh| ssh.exec!(fs_formatter(filesystem)) }
  end

  # Creates ebs volumes for the given node.
  # 
  # @param [ Souffle::Node ] node The node to create ebs volumes for.
  # 
  # @return [ Array ] The list of created ebs volumes.
  def create_ebs(node)
    volumes = Array.new
    node.options[:volume_count].times do
      volumes << @ec2.create_volume(
        node.options.fetch(:aws_snapshot_id, ""),
        node.options[:aws_ebs_size],
        node.try_opt(:aws_availability_zone) )
    end
    node.options[:volumes] = volumes
    volumes
  end

  # Attaches ebs volumes to the given node.
  # 
  # @param [ Souffle::Node ] node The node to attach ebs volumes onto.
  def attach_ebs(node)
    node.options[:volumes].each_with_index do |volume, index|
      @ec2.attach_volume(
        volume[:aws_id],
        node.options[:aws_instance_id],
        volume_id_to_device(index) )
    end
  end

  # Detach and delete all volumes from a given node.
  # 
  # @param [ Souffle::Node ] node The node to destroy ebs volumes from.
  def detach_and_delete_ebs(node)
    detach_ebs(node, force=true)
    delete_ebs(node)
  end

  # Detaches all ebs volumes from a given node.
  # 
  # @param [ Souffle::Node ] node The node to detach volumes from.
  # @param [ true,false ] force Whether or not to force the detachment.
  def detach_ebs(node, force=false)
    node.options[:volumes].each_with_index do |volume, index|
      @ec2.detach_volume(
        volume[:aws_id],
        node.options[:aws_instance_id],
        volume_id_to_device(index),
        force)
    end
  end

  # Deletes the ebs volumes from a given node.
  # 
  # @param [ Souffle::Node ] node The node to delete volumes from.
  def delete_ebs(node)
    node.options[:volumes].each do |volume|
      @ec2.delete_volume(volume[:aws_id])
    end
  end

  # Whether or not to use a vpc instance and subnet for provisioning.
  # 
  # @param [ Souffle::Node ] node The node to check vpc information for.
  # @return [ true,false ] Whether to use a vpc instance and specific subnet.
  def using_vpc?(node)
    !!node.try_opt(:aws_vpc_id) and
    !!node.try_opt(:aws_subnet_id)
  end

  # Checks whether or not the vpc and subnet are setup proeprly.
  # 
  # @param [ Souffle::Node ] node The node to check vpc information for.
  # 
  # @return [ true,false ] Whether or not the vpc is setup.
  def vpc_setup?(node)
    vpc_exists? and subnet_exists?
  end

  # Checks whether or not the vpc currently exists.
  # 
  # @param [ Souffle::Node ] node The node to check vpc information for.
  # 
  # @return [ true,false ] Whether or not the vpc exists.
  def vpc_exists?(node)
    @ec2.describe_vpcs({:filters =>
      { 'vpc-id' => node.try_opt(:aws_vpc_id) } }).any?
  end

  # Checks whether or not the subnet currently exists.
  # 
  # @param [ Souffle::Node ] node The node to check vpc information for.
  # 
  # @return [ true,false ] Whether or not the subnet exists.
  def subnet_exists?(node)
    @ec2.describe_subnets({:filters =>
      { 'subnet-id' => node.try_opt(:aws_subnet_id) } }).any?
  end

  private

  # Yields an ssh object to manage the commands naturally from there.
  # 
  # @param [ Souffle::Node ] node The node to run commands against.
  # @param [ String ] user The user to connect as.
  # @param [ String, NilClass ] pass By default publickey and password auth
  # will be attempted.
  # @param [ Hash ] opts The options hash.
  # @option opts [ Hash ] :net_ssh Options to pass to Net::SSH,
  # see Net::SSH.start
  # @option opts [ Hash ] :timeout (TIMEOUT) default timeout for all #wait_for
  # and #send_wait calls.
  # @option opts [ Boolean ] :reconnect When disconnected reconnect.
  # 
  # @yield [ EventMachine::Ssh::Session ] The ssh session.
  def ssh_block(node, user="root", pass=nil, opts={})
    n = @ec2.describe_instances(node[:aws_instance_id])
    super(n[:private_ip_address], user, pass, opts)
  end

  # Takes the volume count in the array and converts it to a device name.
  # 
  # @note This starts at /dev/hdb and goes to /dev/hdz, etc.
  # 
  # @param [ Fixnum ] volume_id The count in the array for the volume id.
  # 
  # @return [ String ] The device string to mount to.
  def volume_id_to_device(volume_id)
    "/dev/hd#{(volume_id + 98).chr}"
  end

  # Chooses the appropriate formatter for the given filesystem.
  # 
  # @param [ String ] filesystem The filessytem you intend to use.
  # 
  # @param [ String ] The filesystem formatter.
  def fs_formatter(filesystem)
    "mkfs.#{filesystem}"
  end

  # Installs mdadm (multiple device administration) to manage raid.
  # 
  # @param [ Souffle::Node ] node The node to install mdadm on.
  def install_mdadm(node)
    ssh_cmd(node) { |ssh| ssh.exec!("yum install -y mdadm") }
  end

  # Sets up software raid for the given node.
  # 
  # @param [ Souffle::Node ] node The node setup raid for.
  def setup_raid(node)
    install_mdadm(node)
    node.options[:volumes].each_with_index do |volume, index|
    end
  end
end
