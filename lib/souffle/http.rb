require 'sinatra/base'

# The sinatra 
class Souffle::Http < Sinatra::Base

  get '/' do
    "Hello world"
  end
end
