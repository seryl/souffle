require 'sinatra/base'

require 'souffle/state'

# The souffle service REST interface.
class Souffle::Http < Sinatra::Base
  before { content_type :json }

  # Returns the current version of souffle.
  ['/', 'version'].each do |path|
    get path do
      { :name => 'souffle',
        :version => Souffle::VERSION }.to_json
    end
  end

  # Returns the current status of souffle.
  get '/status' do
    { :status => Souffle::State.status }.to_json
  end

  # Returns the id for the created environment or false on failure.
  put '/create' do
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

    provider = Souffle::Provider::AWS.new

    system = Souffle::System.from_hash(data)
    provider.create_system(system)

    { :success => true }.to_json
  end
end
