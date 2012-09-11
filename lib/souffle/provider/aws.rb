require 'right_aws'
require 'securerandom'

require 'souffle/polling_event'

# Monkeypatch RightAws to support EBS delete on termination.
class RightAws::Ec2
  def modify_block_device_delete_on_termination_attribute(instance_id,
      device_name, delete_on_termination)
    request_hash = {'InstanceId' => instance_id}
    prefix = "BlockDeviceMapping.1"
    request_hash["#{prefix}.DeviceName"] = device_name
    request_hash["#{prefix}.Ebs.DeleteOnTermination"] = delete_on_termination
    link = generate_request('ModifyInstanceAttribute', request_hash)
    request_info(link, RightAws::RightBoolResponseParser.new(
      :logger => @logger))
  rescue Exception
    on_exception
  end
end

# The AWS souffle provider.
class Souffle::Provider::AWS < Souffle::Provider::Base
  attr_reader :access_key, :access_secret

  # Setup the internal AWS configuration and object.
  def initialize
    super()
    @access_key    = @system.try_opt(:aws_access_key)
    @access_secret = @system.try_opt(:aws_access_secret)
    @newest_cookbooks = create_cookbooks_tarball

    if Souffle::Config[:debug]
      logger = Souffle::Log.logger
    else
      logger = Logger.new('/dev/null')
    end
    
    @ec2 = RightAws::Ec2.new(
      @access_key, @access_secret,
      :region => @system.try_opt(:aws_region),
      :logger => logger)
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
    wait_until_node_running(node) { tag_node(node, node.try_opt(:tag)) }
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
    }) unless Array(volume_ids).empty?
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
  # @param [ Souffle::Node ] node The node to boot up.
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
  # @param [ Fixnum ] iteration The current retry iteration.
  def partition(node, iteration=0)
    return node.provisioner.error_occurred if iteration == 3
    Souffle::PollingEvent.new(node) do
      timeout 30

      pre_event do
        @partitions = 0
        @provider = node.provisioner.provider
        node.options[:volumes].each_with_index do |volume, index|
          @provider.partition_device(
            node, @provider.volume_id_to_device(index)) do |count|
            @partitions += count
          end
        end
      end

      event_loop do
        if @partitions == node.options[:volumes].size
          event_complete
          node.provisioner.partitioned_device
        end
      end

      error_handler do
        error_msg = "#{node.log_prefix} Timeout during partitioning..."
        Souffle::Log.error error_msg
        @provider.partition(node, iteration+1)
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
    node.options.fetch(:volume_count, 0).times do
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
  # @param [ Fixnum ] poll_timeout The maximum number of seconds to wait.
  # @param [ Fixnum ] poll_interval The interval in seconds to poll EC2.
  def wait_until_node_running(node, poll_timeout=100, poll_interval=2, &blk)
    ec2 = @ec2; Souffle::PollingEvent.new(node) do
      timeout poll_timeout
      interval poll_interval

      pre_event do
        Souffle::Log.info "#{node.log_prefix} Waiting for node running..."
        @provider = node.provisioner.provider
        @blk = blk
      end

      event_loop do
        instance = ec2.describe_instances(
          node.options[:aws_instance_id]).first
        if instance[:aws_state].downcase == "running"
          event_complete
          @blk.call unless @blk.nil?
          @provider.wait_until_ebs_ready(node)
        end
      end

      error_handler do
        error_msg = "#{node.log_prefix} Wait for node running timeout..."
        Souffle::Log.error error_msg
        node.provisioner.error_occurred
      end
    end
  end

  # Polls the EBS volume status until they're ready then runs the given block.
  # 
  # @param [ Souffle::Node ] node The node to wait for EBS on.
  # @param [ Fixnum ] poll_timeout The maximum number of seconds to wait.
  # @param [ Fixnum ] poll_interval The interval in seconds to poll EC2.
  def wait_until_ebs_ready(node, poll_timeout=100, poll_interval=2)
    ec2 = @ec2; Souffle::PollingEvent.new(node) do
      timeout poll_timeout
      interval poll_interval

      pre_event do
        Souffle::Log.info "#{node.log_prefix} Waiting for EBS to be ready..."
        @provider = node.provisioner.provider
        @volume_ids = node.options[:volumes].map { |v| v[:aws_id] }
      end

      event_loop do
        vol_status = ec2.describe_volumes(@volume_ids)
        avail = Array(vol_status).select { |v| v[:aws_status] == "available" }
        if avail.size == vol_status.size
          event_complete
          @provider.attach_ebs(node)
          node.provisioner.created
        end
      end

      error_handler do
        error_msg = "#{node.log_prefix} Waiting for EBS Timed out..."
        Souffle::Log.error error_msg
        node.provisioner.error_occurred
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
      @ec2.modify_block_device_delete_on_termination_attribute(
        node.options[:aws_instance_id],
        volume_id_to_aws_device(index),
        node.try_opt(:delete_on_termination) )
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
  # @param [ Boolean ] force Whether or not to force the
  # detachment.
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
  # @return [ Boolean ] Whether to use a vpc instance and
  # specific subnet.
  def using_vpc?(node)
    !!node.try_opt(:aws_vpc_id) and
    !!node.try_opt(:aws_subnet_id)
  end

  # Checks whether or not the vpc and subnet are setup proeprly.
  # 
  # @param [ Souffle::Node ] node The node to check vpc information for.
  # 
  # @return [ Boolean ] Whether or not the vpc is setup.
  def vpc_setup?(node)
    vpc_exists? and subnet_exists?
  end

  # Checks whether or not the vpc currently exists.
  # 
  # @param [ Souffle::Node ] node The node to check vpc information for.
  # 
  # @return [ Boolean ] Whether or not the vpc exists.
  def vpc_exists?(node)
    @ec2.describe_vpcs({:filters =>
      { 'vpc-id' => node.try_opt(:aws_vpc_id) } }).any?
  end

  # Checks whether or not the subnet currently exists.
  # 
  # @param [ Souffle::Node ] node The node to check vpc information for.
  # 
  # @return [ Boolean ] Whether or not the subnet exists.
  def subnet_exists?(node)
    @ec2.describe_subnets({:filters =>
      { 'subnet-id' => node.try_opt(:aws_subnet_id) } }).any?
  end

  # Provisions a node with the chef/chef-solo configuration.
  # 
  # @todo Setup the chef/chef-solo tar gzip and ssh connections.
  def provision(node)
    if node.try_opt(:chef_provisioner) == :solo
      provision_chef_solo(node, generate_chef_json(node))
    else
      provision_chef_client(node)
    end
    node.provisioner.provisioned
  end

  # Waits for ssh to be accessible for a node for the initial connection and
  # yields an ssh object to manage the commands naturally from there.
  # 
  # @param [ Souffle::Node ] node The node to run commands against.
  # @param [ String ] user The user to connect as.
  # @param [ String, NilClass ] pass By default publickey and password auth
  # will be attempted.
  # @param [ Hash ] opts The options hash.
  # @param [ Fixnum ] poll_timeout The maximum number of seconds to wait.
  # @param [ Fixnum ] iteration The current retry iteration.
  # 
  # @option opts [ Hash ] :net_ssh Options to pass to Net::SSH,
  # see Net::SSH.start
  # @option opts [ Hash ] :timeout (TIMEOUT) default timeout for all #wait_for
  # and #send_wait calls.
  # @option opts [ Boolean ] :reconnect When disconnected reconnect.
  # 
  # @yield [ Eventmachine::Ssh:Session ] The ssh session.
  def wait_for_boot(node, user="root", pass=nil, opts={},
                    poll_timeout=100, iteration=0, &blk)
    return node.provisioner.error_occurred if iteration == 3

    ec2 = @ec2; Souffle::PollingEvent.new(node) do
      timeout poll_timeout
      interval EM::Ssh::Connection::TIMEOUT

      pre_event do
        Souffle::Log.info "#{node.log_prefix} Waiting for ssh..."
        @provider = node.provisioner.provider
        @blk = blk
      end

      event_loop do
        n = ec2.describe_instances(node.options[:aws_instance_id]).first
        unless n.nil?
          key = n[:ssh_key_name]
          if @provider.ssh_key_exists?(key)
            opts[:keys] = @provider.ssh_key(key)
          end
          opts[:password] = pass unless pass.nil?
          opts[:paranoid] = false
          address = n[:private_ip_address]

          EM::Ssh.start(address, user, opts) do |connection|
            connection.errback  { |err| nil }
            connection.callback do |ssh|
              event_complete
              node.provisioner.booted
              @blk.call(ssh) unless @blk.nil?
              ssh.close
            end
          end
        end
      end

      error_handler do
        Souffle::Log.error "#{node.log_prefix} SSH Boot timeout..."
        @provider.wait_for_boot(node, user, pass, opts,
          poll_timeout, iteration+1, &blk)
      end
    end
  end

  # Provisions a box using the chef_solo provisioner.
  # 
  # @param [ String ] node The node to provision.
  # @param [ String ] solo_json The chef solo json string to use.
  def provision_chef_solo(node, solo_json)
    rsync_file(node, @newest_cookbooks, "/tmp")
    solo_config =  "node_name \"#{node.name}.souffle\"\n"
    solo_config << 'cookbook_path "/tmp/cookbooks"'
    ssh_block(node) do |ssh|
      ssh.exec!("sleep 2; tar -zxf /tmp/cookbooks-latest.tar.gz -C /tmp")
      ssh.exec!("echo '#{solo_config}' >/tmp/solo.rb")
      ssh.exec!("echo '#{solo_json}' >/tmp/solo.json")
      ssh.exec!("chef-solo -c /tmp/solo.rb -j /tmp/solo.json")
      rm_files =  "/tmp/cookbooks /tmp/cookbooks-latest.tar.gz"
      rm_files << " /tmp/solo.rb /tmp/solo.json > /tmp/chef_bootstrap"
      ssh.exec!("rm -rf #{rm_files}")
    end
  end

  # Provisions a box using the chef_client provisioner.
  # 
  # @todo Chef client provisioner needs to be completed.
  def provision_chef_client(node)
    ssh_block(node) do |ssh|
      ssh.exec!("chef-client")
    end
  end

  # Rsync's a file to a remote node.
  # 
  # @param [ Souffle::Node ] node The node to connect to.
  # @param [ Souffle::Node ] file The file to rsync.
  # @param [ Souffle::Node ] path The remote path to rsync.
  def rsync_file(node, file, path='.')
    n = @ec2.describe_instances(node.options[:aws_instance_id]).first
    super(n[:private_ip_address], file, path)
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
  # @return [ Hash ] The options hash to pass into ec2 launch instance.
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
  # @return [ String ] The filesystem formatter.
  def fs_formatter(filesystem)
    "mkfs.#{filesystem}"
  end
end
