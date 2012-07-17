$:.unshift File.dirname(__FILE__)
require 'yajl'
require 'eventmachine'
require 'state_machine'
require 'right_aws'

# An orchestrator for setting up isolated chef-managed systems.
module Souffle
  VERSION = "0.0.1"
end

require 'souffle/log'
require 'souffle/exceptions'
require 'souffle/config'
require 'souffle/provider'
require 'souffle/node'
require 'souffle/system'
