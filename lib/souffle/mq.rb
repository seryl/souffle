require 'souffle/state'

require 'amqp'
require 'securerandom'

# The souffle service AMQP interface.
module Souffle::MQ
  extend self

  # Returns the amqp specific configuration parameters.
  #
  # @return [ Hash ] The amqp specific configuration parameters.
  def config
    opts = Hash.new
    Souffle::Config.configuration.each do |k,v|
      if /^amqp/ =~ k.to_s
        opts[k.to_s.gsub('amqp_', '').to_sym] = v
      end
    end
    opts
  end

  # Starts the AMQP worker.
  def initialize_worker(handler=nil)
    self.channel.queue.subscribe(&handler) unless handler.nil?
  end

  # Setup the AMQP connection or return the current AMQP object.
  #
  # @return [ AMQP::Connection ] The AMQP connection.
  def amq
    @amq ||= AMQP.connect({
      :user => config[:user],
      :pass => config[:pass],
      :vhost => config[:vhost],
      :host => config[:host],
      :port => (config[:port] || 5672).to_i,
      :insist => config[:insist] || false,
      :retry => config[:retry] || 5,
      :connection_status => proc do |event|
        case event
        when :connected
          Souffle::Log.info "[souffle] Connected to AMQP"
        when :disconnected
          Souffle::Log.info "[souffle] Disconnected from AMQP"
        end
      end
      })
  end

  # Generate an identity for the current worker.
  #
  # @return [ String ] The current worker identity.
  def identity
    @identity ||= SecureRandom.hex
  end
end
