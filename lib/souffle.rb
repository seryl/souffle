$:.unshift File.dirname(__FILE__)
require 'yajl'
require 'eventmachine'
require 'right_aws'
require 'mixlib/cli'

# An orchestrator for setting up isolated chef-managed systems.
module Souffle
  VERSION = "0.0.1"
end

require 'souffle/log'
require 'souffle/config'
require 'souffle/provider'
require 'souffle/node'
require 'souffle/system'
