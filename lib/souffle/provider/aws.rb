$:.unshift File.dirname(__FILE__)
require 'base'

module Souffle::Provider
  # The AWS souffle provider.
  class AWS < Souffle::Provider::Base
  end
end
