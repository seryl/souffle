require 'sinatra/base'

require 'souffle/state'

# The souffle service REST interface.
class Souffle::Http < Sinatra::Base
  before { content_type :json }

  # Returns the current version of souffle.
  ['/', '/version'].each do |path|
    get path do
      { :name => 'souffle',
        :version => Souffle::VERSION }.to_json
    end
  end

  # Returns the id for the created environment or false on failure.
  put '/system' do
    begin
      data = JSON.parse(request.body.read, :symbolize_keys => true)
    rescue
      status 415
      return {  :success => false,
                :message => "Invalid json in request." }.to_json
    end

    user = data[:user]
    msg =  "Http request to create a new system"
    msg << " for user: #{user}" if user
    Souffle::Log.debug msg
    Souffle::Log.debug data.to_s

    system = Souffle::System.from_hash(data)
    provider = Souffle::Provider.plugin(system.try_opt(:provider)).new
    system_tag = provider.create_system(system)

    begin
      { :success => true, :system => system_tag }.to_json
    rescue Exception => e
      Souffle::Log.error "#{e.message}:\n#{e.backtrace.join("\n")}"
      { :success => false }.to_json
    end
  end

  # Returns the current status of souffle.
  get '/system' do
    access_key    = Souffle::Config[:aws_access_key]
    access_secret = Souffle::Config[:aws_access_secret]
    logger = Logger.new('/dev/null')
    ec2 = RightAws::Ec2.new(
      access_key, access_secret,
      :region => Souffle::Config[:aws_region],
      :logger => logger)

    filters = {}
    filters[:filters]['tag-key'] = "souffle"
    if Souffle::Config.has_key?(:aws_subnet_id)
      filters[:filters]['subnet_id'] = Souffle::Config[:aws_subnet_id]
    end

    ec2.describe_instances(filters).inject({}) do |slist, instance|
      slist[instance[:tags]["souffle"]] ||= Hash.new
      slist[instance[:tags]["souffle"]][:nodes] ||= Array.new
      slist[instance[:tags]["souffle"]][:user]  ||= instance[:tags]["user"]

      instance_info = {
        :name => instance[:tags]["Name"],
        :ipaddress => instance[:private_ip_address],
        :state => instance[:aws_state].downcase
      }

      slist[instance[:tags]["souffle"]][:nodes] << instance_info
      slist
    end.to_json
  end

  # Returns the system-specific status.
  get '/system/:system' do
    access_key    = Souffle::Config[:aws_access_key]
    access_secret = Souffle::Config[:aws_access_secret]
    logger = Logger.new('/dev/null')
    ec2 = RightAws::Ec2.new(
      access_key, access_secret,
      :region => Souffle::Config[:aws_region],
      :logger => logger)
    
    ec2.describe_instances( :filters => {
      'tag-key' => "souffle", 'tag-value' => params[:system] }
      ).inject({}) do |slist, instance|
      slist[instance[:tags]["souffle"]] ||= Hash.new
      slist[instance[:tags]["souffle"]][:nodes] ||= Array.new
      slist[instance[:tags]["souffle"]][:user]  ||= instance[:tags]["user"]

      instance_info = {
        :name => instance[:tags]["Name"],
        :ipaddress => instance[:private_ip_address],
        :state => instance[:aws_state].downcase
      }

      slist[instance[:tags]["souffle"]][:nodes] << instance_info
      slist
    end.to_json
  end

  # Deletes a given system.
  delete '/system/:system' do
    access_key    = Souffle::Config[:aws_access_key]
    access_secret = Souffle::Config[:aws_access_secret]
    logger = Logger.new('/dev/null')
    ec2 = RightAws::Ec2.new(
      access_key, access_secret,
      :region => Souffle::Config[:aws_region],
      :logger => logger)

    remove_list = ec2.describe_instances( :filters => {
      'tag-key' => "souffle", 'tag-value' => params[:system] }
      ).inject([]) do |instance_list, instance|
      instance_list << instance[:aws_instance_id]
      instance_list
    end
    ec2.terminate_instances(remove_list).to_json
  end
end
