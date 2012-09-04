require 'sinatra/base'

require 'souffle/state'

# The souffle service REST interface.
class Souffle::Http < Sinatra::Base
  before { content_type :json }

  # Returns the current version of souffle.
  get '/' do
    { :name => 'souffle',
      :version => Souffle::VERSION }.to_json
  end

  # Returns the current status of souffle.
  get '/status' do
    { :status => Souffle::State.status }.to_json
  end

  # Returns the id for the created environment or false on failure.
  put '/create' do
    Souffle::Log.info "Http request to create new system"
  end
end
