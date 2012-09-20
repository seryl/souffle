# Souffle specific exceptions; intended for debugging purposes.
class Souffle::Exceptions
  
  # Application level error.
  class Application < RuntimeError; end
  # Provider level error.
  class Provider < RuntimeError; end

  # Runlist Name cannot be nil or empty and must be a word [A-Za-z0-9_:].
  class InvalidRunlistName < RuntimeError; end
  # Runlist Type cannot be nil or empty and must be one of (role|recipe).
  class InvalidRunlistType < RuntimeError; end

  # Node children must respond to dependencies and run_list.
  class InvalidChild < RuntimeError; end
  # Node parents must respond to dependencies and run_list.
  class InvalidParent < RuntimeError; end

  # The provider must exist in souffle/providers.
  class InvalidProvider < RuntimeError; end

  # The system hash must have a nodes key with a list of nodes.
  class InvalidSystemHash < RuntimeError; end

  # The souffle ssh directory must have writable permissions.
  class PermissionErrorSshKeys < RuntimeError; end

  # The AWS Instance searched for does not exist.
  class AwsInstanceDoesNotExist < RuntimeError; end

  # The AWS Keys are invalid.
  class InvalidAwsKeys < RuntimeError; end

  # Plugin does not exist.
  class PluginDoesNotExist < RuntimeError; end
end
