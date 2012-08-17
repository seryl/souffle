require 'right_aws'
require 'securerandom'

# The AWS souffle provider.
class Souffle::Provider::AWS < Souffle::Provider::Base
  attr_reader :access_key, :access_secret

  # Setup the internal AWS configuration and object.
  def initialize
    super()
    @access_key    = @system.try_opt(:aws_access_key)
    @access_secret = @system.try_opt(:aws_access_secret)

    @ec2 = RightAws::Ec2.new(
      @access_key, @access_secret,
      :region => @system.try_opt(:aws_region),
      :logger => Souffle::Log.logger)
    rescue
      raise Souffle::Exceptions::InvalidAwsKeys,
            "AWS access keys are required to operate on EC2"
  end

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
    system.provisioner = Souffle::Provisioner::System.new(system, self)
    system.provisioner.initialized
  end

  # Takes a list of nodes and returns the list of their aws instance_ids.
  # 
  # @param [ Array ] nodes The list of nodes to get instance_id's from.
  def instance_id_list(nodes)
    Array(nodes).map { |n| n.options[:aws_instance_id] }
  end

  # Takes a node definition and begins the provisioning process.
  # 
  # @param [ Souffle::Node ] node The node to instantiate.
  # @param [ String ] tag The tag to use for the node.
  def create_node(node, tag=nil)
    opts = prepare_node_options(node)
    node.options[:tag] = tag unless tag.nil?

    create_ebs(node)
    instance_info = @ec2.launch_instances(
      node.try_opt(:aws_image_id), opts).first
    
    node.options[:aws_instance_id] = instance_info[:aws_instance_id]
    tag_node(node, node.try_opt(:tag))

    wait_until_node_running(node)
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
  def kill(nodes)
    @ec2.terminate_instances(instance_id_list(nodes))
  end

  # Takes a list of nodes kills them and then recreates them.
  # 
  # @param [ Souffle::Node ] nodes The list of nodes to kill and recreate.
  def kill_and_recreate(nodes)
    kill(nodes)
    @provisioner.reclaimed
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
    dev_list = devices.map { |s| "#{s}1" }
    mdadm_string =  "/sbin/mdadm --create /dev/md#{md_device} "
    mdadm_string << "--chunk=#{chunk} --level=#{level} "
    mdadm_string << "--raid-devices=#{devices.size} #{dev_list.join(' ')}"

    export_mdadm = "/sbin/mdadm --detail --scan > /etc/mdadm.conf"

    ssh_block(node) do |ssh|
      ssh.exec!(mdadm_string)
      ssh.exec!(export_mdadm)
      yield if block_given?
    end
  end

  # Wait for the machine to boot up.
  # 
  # @parameter [ Souffle::Node ] The node to boot up.
  def boot(node)
    wait_for_boot(node)
  end

  # Formats all of the devices on a given node for the provisioner interface.
  # 
  # @param [ Souffle::Node ] node The node to format it's new partitions.
  def format_device(node)
    partition_device(node, "/dev/md0", "8e") do
      _format_device(node, "/dev/md0p1")
    end
  end

  # Formats a device on a given node with the provided filesystem.
  # 
  # @param [ Souffle::Node ] node The node to format a device on.
  # @param [ String ] device The device to format.
  # @param [ String ] filesystem The filesystem to use when formatting.
  def _format_device(node, device, filesystem="ext4")
    return if node.options[:volumes].nil?
    setup_lvm(node)
    ssh_block(node) do |ssh|
      ssh.exec!("#{fs_formatter(filesystem)} #{device}")
      mount_lvm(node) { node.provisioner.device_formatted }
    end
  end

  # Partition each of the volumes with raid for the node.
  # 
  # @param [ Souffle::Node ] node The node to partition the volumes on.
  # @param [ Fixnum ] timeout The timeout in seconds before failing.
  def partition(node, timeout=60)
    partitions = 0
    node.options[:volumes].each_with_index do |volume, index|
      partition_device(node, volume_id_to_device(index)) do |count|
        partitions += count
      end
    end
    timer = EM.add_periodic_timer(2) do
      if partitions == node.options[:volumes].size
        timer.cancel
        node.provisioner.partitioned_device
      end
    end

    EM::Timer.new(timeout) do
      unless partitions == node.options[:volumes].size
        error_msg =  node.log_prefix
        error_msg << " Timeout during partitioning..."
        Souffle::Log.error error_msg
        timer.cancel
        node.provisioner.error_occurred
      end
    end
  end

  # Partitions a device on a given node with the given partition_type.
  # 
  # @note Currently this is a naive implementation and uses the full disk.
  # 
  # @param [ Souffle::Node ] node The node to partition a device on.
  # @param [ String ] device The device to partition.
  # @param [ String ] partition_type The type of partition to create.
  def partition_device(node, device, partition_type="fd")
    partition_cmd =  "echo \",,#{partition_type}\""
    partition_cmd << "| /sbin/sfdisk #{device}"
    ssh_block(node) do |ssh|
      ssh.exec!("#{partition_cmd}")
      yield(1) if block_given?
    end
  end

  # Sets up the lvm partition for the raid devices.
  # 
  # @param [ Souffle::Node ] node The node to setup lvm on.
  def setup_lvm(node)
    return if node.options[:volumes].nil?
    ssh_block(node) do |ssh|
      ssh.exec!("pvcreate /dev/md0p1")
      ssh.exec!("vgcreate VolGroup00 /dev/md0p1")
      ssh.exec!("lvcreate -l 100%vg VolGroup00 -n data")
    end
  end

  # Mounts the newly created lvm configuration and adds it to fstab.
  # 
  # @param [ Souffle::Node ] node The node to mount lvm on.
  def mount_lvm(node)
    fstab_str =  "/dev/md0p1      /data"
    fstab_str << "     ext4    noatime,nodiratime  1  1"

    mount_str =  "mount -o rw,noatime,nodiratime"
    mount_str << " /dev/mapper/VolGroup00-data /data"
    ssh_block(node) do |ssh|
      ssh.exec!("mkdir /data")
      ssh.exec!(mount_str)
      ssh.exec!("echo #{fstab_str} >> /etc/fstab")
      ssh.exec!("echo #{fstab_str} >> /etc/mtab")
      yield if block_given?
    end
  end

  # Installs mdadm (multiple device administration) to manage raid.
  # 
  # @param [ Souffle::Node ] node The node to install mdadm on.
  def setup_mdadm(node)
    ssh_block(node) do |ssh|
      ssh.exec!("/usr/bin/yum install -y mdadm")
    end
    node.provisioner.mdadm_installed
  end

  # Sets up software raid for the given node.
  # 
  # @param [ Souffle::Node ] node The node setup raid for.
  def setup_raid(node)
    volume_list = []
    node.options[:volumes].each_with_index do |volume, index|
      volume_list << volume_id_to_device(index)
    end
    create_raid(node, volume_list) { node.provisioner.raid_initialized }
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
        node.try_opt(:aws_snapshot_id),
        node.try_opt(:aws_ebs_size),
        node.try_opt(:aws_availability_zone) )
    end
    node.options[:volumes] = volumes
    volumes
  end

  # Polls the EC2 instance information until it is in the running state.
  # 
  # @param [ Souffle::Node ] node The node to wait until running on.
  # @param [ Fixnum ] timeout The maximum number of seconds to wait.
  # @param [ Fixnum ] period The interval in seconds to poll EC2.
  def wait_until_node_running(node, timeout=200, period=2)
    Souffle::Log.info "#{node.log_prefix} Waiting for node to be running..."
    node_running = false

    timer = EM.add_periodic_timer(period) do
      instance = @ec2.describe_instances(node.options[:aws_instance_id]).first
      if instance[:aws_state].downcase == "running"
        node_running = true
        timer.cancel
        wait_until_ebs_ready(node)
      end
    end

    t_out = EM::Timer.new(timeout) do
      unless node_running
        error_msg =  node.log_prefix
        error_msg << " Wait for node running timeout..."
        Souffle::Log.error error_msg
        node.provisioner.error_occurred
        timer.cancel
      end
    end
  end

  # Polls the EBS volume status until they're ready then runs the given block.
  # 
  # @param [ Souffle::Node ] node The node to wait for EBS on.
  # @param [ Fixnum ] timeout The maximum number of seconds to wait for ebs.
  # @param [ Fixnum ] period The interval in seconds to poll EC2.
  def wait_until_ebs_ready(node, timeout=200, period=2)
    Souffle::Log.info "#{node.log_prefix} Waiting for EBS to be ready..."
    ebs_ready = false
    volume_ids = node.options[:volumes].map { |v| v[:aws_id] }
    timer = EM.add_periodic_timer(period) do
      vol_status = @ec2.describe_volumes(volume_ids)
      avail = Array(vol_status).select { |v| v[:aws_status] == "available" }
      if avail.size == vol_status.size
        attach_ebs(node)
        timer.cancel
        node.provisioner.created
      end
    end

    t_out = EM::Timer.new(timeout) do
      unless ebs_ready
        error_msg =  node.log_prefix
        error_msg << "Waiting for EBS Timed out..."
        Souffle::Log.error error_msg
        node.provisioner.error_occurred
        timer.cancel
      end
    end
  end

  # Attaches ebs volumes to the given node.
  # 
  # @param [ Souffle::Node ] node The node to attach ebs volumes onto.
  def attach_ebs(node)
    Souffle::Log.info "#{node.log_prefix} Attaching EBS..."
    node.options[:volumes].each_with_index do |volume, index|
      @ec2.attach_volume(
        volume[:aws_id],
        node.options[:aws_instance_id],
        volume_id_to_aws_device(index) )
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
        volume_id_to_aws_device(index),
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

  # Waits for ssh to be accessible for a node for the initial connection and
  # yields an ssh object to manage the commands naturally from there.
  # 
  # @param [ Souffle::Node ] node The node to run commands against.
  # @param [ String ] user The user to connect as.
  # @param [ String, NilClass ] pass By default publickey and password auth
  # will be attempted.
  # @param [ Hash ] opts The options hash.
  # @param [ Fixnum ] timeout The time to wait before timing out.
  # @option opts [ Hash ] :net_ssh Options to pass to Net::SSH,
  # see Net::SSH.start
  # @option opts [ Hash ] :timeout (TIMEOUT) default timeout for all #wait_for
  # and #send_wait calls.
  # @option opts [ Boolean ] :reconnect When disconnected reconnect.
  # 
  # @yield [ Eventmachine::Ssh:Session ] The ssh session.
  def wait_for_boot(node, user="root", pass=nil, opts={},
                    timeout=200)
    n = @ec2.describe_instances(node.options[:aws_instance_id]).first
    is_booted = false
    if n.nil?
      raise AwsInstanceDoesNotExist,
        "The AWS instance (#{node.options[:aws_instance_id]}) does not exist."
    else
      key = n[:ssh_key_name]
      opts[:keys] = ssh_key(key) if ssh_key_exists?(key)
      opts[:password] = pass unless pass.nil?
      opts[:paranoid] = false
      address = n[:private_ip_address]
      Souffle::Log.info "#{node.log_prefix} Waiting for ssh..."
      timer = EM::PeriodicTimer.new(EM::Ssh::Connection::TIMEOUT) do
        EM::Ssh.start(address, user, opts) do |connection|
          connection.errback  { |err| nil }
          connection.callback do |ssh|
            timer.cancel
            is_booted = true
            node.provisioner.booted
            yield(ssh) if block_given?
            ssh.close
          end
        end
      end

      EM::Timer.new(timeout) do
        unless is_booted
          Souffle::Log.error "#{node.log_prefix} SSH Boot timeout..."
          node.provisioner.error_occurred
          timer.cancel
        end
      end
    end
  end

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
    n = @ec2.describe_instances(node.options[:aws_instance_id]).first
    if n.nil?
      raise AwsInstanceDoesNotExist,
        "The AWS instance (#{node.options[:aws_instance_id]}) does not exist."
    else
      key = n[:ssh_key_name]
      opts[:keys] = ssh_key(key) if ssh_key_exists?(key)
      super(n[:private_ip_address], user, pass, opts)
    end
  end

  # Prepares the node options using the system or global defaults.
  # 
  # @param [ Souffle::Node ] node The node you wish to prepare options for.
  # 
  # @reutnr [ Hash ] The options hash to pass into ec2 launch instance.
  def prepare_node_options(node)
    opts = Hash.new
    opts[:instance_type] = node.try_opt(:aws_instance_type)
    opts[:min_count] = 1
    opts[:max_count] = 1
    if using_vpc?(node)
      opts[:subnet_id] = node.try_opt(:aws_subnet_id)
      opts[:aws_subnet_id] = node.try_opt(:aws_subnet_id)
      opts[:aws_vpc_id] = Array(node.try_opt(:aws_vpc_id))
      opts[:group_ids] = Array(node.try_opt(:group_ids))
    else
      opts[:group_names] = node.try_opt(:group_names)
    end
    opts[:key_name] = node.try_opt(:key_name)
    opts
  end

  # Takes the volume count in the array and converts it to a device name.
  # 
  # @note This starts at /dev/xvda and goes to /dev/xvdb, etc.
  # And due to the special case on AWS, skips /dev/xvde.
  # 
  # @param [ Fixnum ] volume_id The count in the array for the volume id.
  # 
  # @return [ String ] The device string to mount to.
  def volume_id_to_device(volume_id)
    if volume_id >= 4
      volume_id += 1
    end
    "/dev/xvd#{(volume_id + "a".ord).chr}"
  end

  # Takes the volume count in the array and converts it to a device name.
  # 
  # @note This starts at /dev/xvda and goes to /dev/xvdb, etc.
  # And due to the special case on AWS, skips /dev/xvde.
  # 
  # @param [ Fixnum ] volume_id The count in the array for the volume id.
  # 
  # @return [ String ] The device string to mount to.
  def volume_id_to_aws_device(volume_id)
    if volume_id >= 4
      volume_id += 1
    end
    "/dev/hd#{(volume_id + "a".ord).chr}"
  end

  # Chooses the appropriate formatter for the given filesystem.
  # 
  # @param [ String ] filesystem The filessytem you intend to use.
  # 
  # @param [ String ] The filesystem formatter.
  def fs_formatter(filesystem)
    "mkfs.#{filesystem}"
  end
end
