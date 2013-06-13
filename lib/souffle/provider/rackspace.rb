require 'fog'
require 'souffle/polling_event'

# The RackspaceV2 souffle provider.
class Souffle::Provider::Rackspace < Souffle::Provider::Base
  attr_reader :access_name, :access_key

  # Setup the internal Rackspace configuration and object.
  def initialize
    super()
    @access_name = @system.try_opt(:rackspace_access_name)
    @access_key = @system.try_opt(:rackspace_access_key)
    #@newest_cookbooks = create_cookbooks_tarball

    if Souffle::Config[:debug]
      logger = Souffle::Log.logger
    else
      logger = Logger.new('/dev/null')
    end
    
    @rackspace = Fog::Compute::RackspaceV2.new(
      :rackspace_api_key  => @system.try_opt(:rackspace_access_key),#@access_key,
      :rackspace_username => @system.try_opt(:rackspace_access_name),#@access_name,
      :rackspace_endpoint => @system.try_opt(:rackspace_endpoint))
    rescue => e
      raise Souffle::Exceptions::InvalidRackspaceKeys,
            "Rackspace keys are required to operate. Key: #{@system.try_opt(:rackspace_access_key)} username: #{@system.try_opt(:rackspace_access_name)} endpoint: #{@system.try_opt(:rackspace_endpoint)}"
  end

  # Generates a prefixed unique tag.
  # 
  # @param [ String ] tag_prefix The tag prefix to use.
  # 
  # @return [ String ] The unique tag with prefix.
  def generate_tag(tag_prefix="sys")
    if tag_prefix
      "#{tag_prefix}-#{SecureRandom.hex(4)}"
    else
      SecureRandom.hex(4)
    end
  end
    
  # Creates a system using rackspace as the provider.
  # 
  # @param [ Souffle::System ] system The system to instantiate.
  # @param [ String ] tag_prefix The tag prefix to use for the system.
  def create_system(system, tag_prefix="souffle")
    system.options[:tag] = generate_tag(tag_prefix)
    system.provisioner = Souffle::Provisioner::System.new(system, self)
    system.provisioner.initialized
    system.options[:tag]
  end

  # Takes a list of nodes and returns the list of their rackspace instance_ids.
  # 
  # @param [ Array ] nodes The list of nodes to get instance_id's from.
  def instance_id_list(nodes)
    Array(nodes).map { |n| n.options[:rackspace_instance_id] }
  end

  # Takes a node definition and begins the provisioning process.
  # 
  # @param [ Souffle::Node ] node The node to instantiate.
  # @param [ String ] tag The tag to use for the node.
  def create_node(node, tag=nil)
    node.options[:chef_provisioner] = node.try_opt(:type)
    disk_config = node.try_opt(:rackspace_disk_config) || "AUTO"
    instance_info = @rackspace.servers.create(
      :flavor_id => node.try_opt(:rackspace_flavor_id),
      :image_id => node.try_opt(:rackspace_image_id),
      :name => node.name,
      :disk_config => disk_config)
    Souffle::Log.info "#{node.name} Instance ID #{instance_info.id}"
    node.options[:rackspace_instance_id] = instance_info.id
    node.options[:node_password] = instance_info.password
    node.options[:node_name] = [node.name, node.domain].compact.join('.')
    wait_until_node_running(node) { node.provisioner.created }
  end

  # Takes a list of nodes and kills them. (Haha)
  # 
  # @param [ Souffle::Node ] nodes The list of nodes to terminate.
  def kill(nodes)
    instance_id_list(nodes).each do |n|
      Souffle::Log.info "Killing #{n}"
      @rackspace.delete_server(n)
    end
  end
  
  # Takes a list of nodes kills them and then recreates them.
  # 
  # @param [ Souffle::Node ] nodes The list of nodes to kill and recreate.
  def kill_and_recreate(nodes)
    kill(nodes)
    nodes.each do |n|
      n.provisioner.reclaimed
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
    node.provisioner.device_formatted
  end

  # Partition each of the volumes with raid for the node.
  # 
  # @param [ Souffle::Node ] node The node to partition the volumes on.
  # @param [ Fixnum ] iteration The current retry iteration.
  def partition(node, iteration=0)
    node.provisioner.partitioned_device
  end

  # Installs mdadm (multiple device administration) to manage raid.
  # 
  # @param [ Souffle::Node ] node The node to install mdadm on.
  def setup_mdadm(node)
    ssh_block(node) do |ssh|
      Souffle::Log.info "setup_mdadm: SSH: #{ssh}"
      ssh.exec!("/usr/bin/yum install -y mdadm")
      node.provisioner.mdadm_installed
    end
  end

  # Sets up software raid for the given node.
  # 
  # @param [ Souffle::Node ] node The node setup raid for.
  def setup_raid(node)
    node.provisioner.raid_initialized
  end

  # Polls the EC2 instance information until it is in the running state.
  # 
  # @param [ Souffle::Node ] node The node to wait until running on.
  # @param [ Fixnum ] poll_timeout The maximum number of seconds to wait.
  # @param [ Fixnum ] poll_interval The interval in seconds to poll EC2.
  def wait_until_node_running(node, poll_timeout=600, poll_interval=30, &blk)
    rackspace = @rackspace; Souffle::PollingEvent.new(node) do
      timeout poll_timeout
      interval poll_interval

      pre_event do
        Souffle::Log.info "#{node.log_prefix} Waiting for node running..."
        @provider = node.provisioner.provider
        @blk = blk
      end

      event_loop do
        instance = @provider.get_server(node)
        if instance.state.downcase == "active"
          event_complete
          @blk.call unless @blk.nil?
        elsif instance.state.downcase == "error"
          event_complete
          error_msg = "#{node.log_prefix} Error on Node Boot..."
          Souffle::Log.error error_msg
          node.provisioner.error_occurred
        end
      end

      error_handler do
        error_msg = "#{node.log_prefix} Wait for node running timeout..."
        Souffle::Log.error error_msg
        node.provisioner.error_occurred
      end
    end
  end
  
  # Provisions a node with the chef/chef-solo configuration.
  # 
  # @todo Setup the chef/chef-solo tar gzip and ssh connections.
  def provision(node)
    set_hostname(node)
    setup_dns(node) unless node.try_opt(:dns_provider).nil?
    if node.try_opt(:chef_provisioner).to_s.downcase == "solo"
      provision_chef_solo(node, generate_chef_json(node))
    else
      provision_chef_client(node)
    end
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

    rackspace=@rackspace
    n = get_server(node)
    Souffle::PollingEvent.new(node) do
      timeout poll_timeout
      interval 30

      pre_event do
        Souffle::Log.info "#{node.log_prefix} Waiting for ssh..."
        @provider = node.provisioner.provider
        @blk = blk
      end

      event_loop do
        unless n.nil?
          if pass.nil?
            pass = node.options[:node_password]
          end
          opts[:password] = pass unless pass.nil?
          opts[:paranoid] = false
          address = n.addresses["private"].first["addr"]
          Souffle::Log.info "USER #{user} PASS #{pass} IP #{address} OPTS #{opts}"
          EM::Ssh.start(address, user, opts) do |connection|
            connection.errback  { |err| nil }
            connection.callback do |ssh|
              ssh.exec!("touch /root/.noupdate")
              event_complete
              if node.try_opt(:rack_connect)
                @provider.wait_for_rackconnect(node)
              else
                node.provisioner.booted
              end
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

  def wait_for_rackconnect(node, iteration=0)
    max_iterations = 5
    return node.provisioner.error_occurred if iteration == max_iterations

    rackconnect_test = "curl -s -S https://ord.api.rackconnect.rackspace.com/v1/automation_status?format=JSON"
    
    Souffle::PollingEvent.new(node) do
      timeout 400
      interval 30

      pre_event do
        Souffle::Log.info "#{node.log_prefix} Waiting for rackconnect... (#{iteration}/#{max_iterations})"
        @provider = node.provisioner.provider
      end

      event_loop do
        n = @provider.get_server(node)
        unless n.nil?
          status = n.metadata["rackconnect_automation_status"]
          if (status.to_s =~ /deployed/i)
            event_complete
            node.provisioner.booted
          elsif (status.to_s =~ /failed/i)
            event_complete
            node.provisioner.error_occurred
          end
        end
      end

      error_handler do
        Souffle::Log.error "#{node.log_prefix} Rackconnect timeout..."
        @provider.wait_for_rackconnect(node, iteration+1)
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
      node.provisioner.provisioned
    end
  end

  # Provisions a box using the chef_client provisioner.
  # 
  # @todo Chef client provisioner needs to be completed.
  # Provisions a box using the chef_client provisioner.
  # 
  # @todo Chef client provisioner needs to be completed.
  def provision_chef_client(node)
    validation_pem = node.try_opt(:validation_pem)
    client_config = "log_level\t:info
    log_location\tSTDOUT
    chef_server_url\t'#{node.try_opt(:chef_server)}'
    validation_client_name\t'chef-validator'"
    client_cmds =  "chef-client -N #{node.options[:node_name]} "
    client_cmds << "-j /tmp/client.json "
    client_cmds << "-S #{node.try_opt(:chef_server)} "
    client_cmds << "-E #{node.try_opt(:chef_environment)} " unless node.try_opt(:chef_environment).nil?
    n = node; ssh_block(node) do |ssh|
      write_temp_chef_json(ssh, n)
      ssh.exec!("mkdir /etc/chef")
      ssh.exec!("echo \"#{client_config}\" >> /etc/chef/client.rb")
      ssh.exec!("echo \"#{validation_pem}\" >> /etc/chef/validation.pem")
      ssh.exec!("curl -L https://www.opscode.com/chef/install.sh | bash -s -- -v 10.14.4")
      status = ssh.exec!("#{client_cmds} ; echo $?").split("\n").last
      if status != "0"
        Souffle::Log.error "#{node.log_prefix} Chef-client failure... Status #{status}"
      else
        cleanup_temp_chef_files(ssh, n)
      end
      node.provisioner.provisioned
    end
  end

  # Sets dns for the given node.
  # 
  # @param [ Souffle:Node ] node The node to update dns for.
  def setup_dns(node)
    n = get_server(node)
    dns = Souffle::DNS.plugin(system.try_opt(:dns_provider)).new
    #dns.delete_entry(node)
    dns.create_entry(node,n.ipv4_address)
  end
   
  # Sets the hostname for the given node for the chef run.
  # 
  # @param [ Souffle:Node ] node The node to update the hostname for.
  def set_hostname(node)
    local_lookup = "127.0.0.1       #{node.options[:node_name]} #{node.name}\n"
    fqdn = node.options[:node_name]
    ssh_block(node) do |ssh|
      ssh.exec!("hostname '#{fqdn}'")
      ssh.exec!("echo \"#{local_lookup}\" >> /etc/hosts")
      ssh.exec!("echo \"HOSTNAME=#{fqdn}\" >> /etc/sysconfig/network")
    end
  end
      
  # Rsync's a file to a remote node.
  # 
  # @param [ Souffle::Node ] node The node to connect to.
  # @param [ Souffle::Node ] file The file to rsync.
  # @param [ Souffle::Node ] path The remote path to rsync.
  def rsync_file(node, file, path='.')
    n = @rackspace.servers.get(node.options[:rackspace_instance_id])
    super(n.addresses["private"].first["addr"], file, path)
  end
  
  # Writes a temporary chef-client json file.
  #
  # @param [ EventMachine::Ssh::Connection ] ssh The em-ssh connection.
  # @param [ Souffle::Node ] node The given node to work with.
  def write_temp_chef_json(ssh, node)
    ssh.exec!("echo '''#{generate_chef_json(node)}''' > /tmp/client.json")
  end

  # Removes the temporary chef-client files.
  #
  # @param [ EventMachine::Ssh::Connection ] ssh The em-ssh connection.
  # @param [ Souffle::Node ] node The given node to work with.
  def cleanup_temp_chef_files(ssh, node)
    ssh.exec!("rm -f /tmp/client.json")
    ssh.exec!("rm -f /etc/chef/validation.pem")
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
   n = get_server(node)
    if n.nil?
      raise RackspaceInstanceDoesNotExist,
        "The Rackspace instance (#{node.options[:rackspace_instance_id]}) does not exist."
    else
      if pass.nil?
        pass = node.options[:node_password]
      end
      opts[:password] = pass unless pass.nil?
      Souffle::Log.info "USER #{user} PASS #{pass} IP #{n.addresses["private"].first["addr"]} OPTS #{opts}"
      super(n.addresses["private"].first["addr"], user, pass, opts)
    end
  end
  
    
  # Yields a rackspace server object to manage the commands naturally from there.
  # 
  # @param [ Souffle::Node ] node The node to run commands against.
  def get_server(node)
    rackspace = @rackspace.servers.get(node.options[:rackspace_instance_id])
    rescue => e
      raise Souffle::Exceptions::RackspaceApiError,
        "#{e.class} :: #{e}"
    return rackspace unless rackspace.nil?
  end
  
  class << self
    # Updates the souffle status with the latest AWS information.
    # 
    # @param [ RightAws::Ec2 ] ec2 The ec2 object to use for the status update.
    def update_status(rackspace=nil)
      rackspace = get_base_rackspace_info if rackspace.nil?
      return if rackspace.nil?
    end

    # Returns the base (configured) ec2 object for status updates.
    # 
    # @return [ RightAws::Ec2 ] The base RightAws Ec2 object.
    def get_base_rackspace_info
      access_name = Souffle::Config[:rackspace_access_name]
      access_key = Souffle::Config[:rackspace_access_key]
      rackspace_endpoint = Souffle::Config[:rackspace_endpoint]

      if Souffle::Config[:debug]
        logger = Souffle::Log.logger
      else
        logger = Logger.new('/dev/null')
      end

      Fog::Compute::RackspaceV2.new(
        :rackspace_api_key  => access_key,
        :rackspace_username => access_name,
        :rackspace_endpoint => rackspace_endpoint)
    rescue
      nil
    end
  end

end
