$:.unshift File.dirname(__FILE__)

# Module namespace for souffle providers.
module Souffle::Provider; end

require 'provider/base'
require 'provider/aws'
