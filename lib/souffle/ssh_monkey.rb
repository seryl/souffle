require 'em-ssh'

# Monkeypatching connect on ssh so it doesn't spam the log.
class Net::SSH::Authentication::KeyManager
  def use_agent?
    false
  end
end
