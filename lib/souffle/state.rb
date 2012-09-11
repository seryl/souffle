require 'mixlib/config'

# The singleton state object for the souffle server.
class Souffle::State
  extend Mixlib::Config

  # Return the configuration itself upon inspection.
  def self.inspect
    configuration.inspect
  end
end
