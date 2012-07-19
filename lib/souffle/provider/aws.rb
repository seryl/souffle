require 'souffle/provider'

# The AWS souffle provider.
class Souffle::Provider::AWS < Souffle::Provider

  # Setup the internal AWS configuration and object.
  def setup
    @access_key    = Souffle::Config[:aws_access_key]
    @access_secret = Souffle::Config[:aws_access_secret]
  end
  
  # The name of the given provider.
  def name; "AWS"; end

  # Creates a raid array with the given requirements.
  def create_raid
  end
end
