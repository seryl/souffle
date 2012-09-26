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

  # Returns the current status of souffle.
  get '/system' do
    { :status => Souffle::State.status }.to_json
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

  # Returns the system-specific status.
  get '/status/:system' do
    { :success => false,
      :message => "Not yet implemented." }.to_json
  end

  # Deletes a given system.
  delete '/system/:system' do
    { :success => false,
      :message => "Not yet implemented." }.to_json
  end
end
