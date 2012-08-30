# Eventmachine polling event helper.
class Souffle::PollingEvent
  # The node to run the polling event against.
  attr_accessor :node

  # The current state of the polling event.
  attr_accessor :state

  # The interval to run the periodic timer against the event_loop.
  attr_reader :interval

  # The timeout (in seconds) for the periodic timer.
  attr_reader :timeout

  # The proc to run prior to the periodic event loop.
  attr_accessor :pre_event

  # The event loop proc, should call complete on success.
  attr_accessor :event_loop

  # The proc to run when the timeout has occurred.
  attr_accessor :error_handler

  # Create a new polling even instance.
  # 
  # @param [ Souffle::Node ] node The node to run the polling event against.
  # @param [ Proc ] blk The block to evaluate in the instance context.
  # 
  # @example
  #     node = Souffle::Node.new
  #     node.name = "example_node"
  # 
  #     EM.run do
  #       evt = PollingEvent.new(node) do
  #         interval 1
  #         timeout 5
  #         pre_event     { puts "at the beginning" }
  #         event_loop    { puts "inside of the event loop" }
  #         error_handler { puts "in error handler"; EM.stop }
  #       end
  #     end
  # 
  def initialize(node, &blk)
    @state = Hash.new
    @node = node
    instance_eval(&blk) if block_given?
    initialize_defaults
    initialize_state
    start_event
  end

  # Changes or returns the setting for a parameter.
  %w( interval timeout ).each do |setting|
    class_eval %[
      def #{setting}(value=nil)
        return @#{setting} if value.nil?
        @#{setting} = value unless @#{setting} == value
      end
    ]
  end

  # Sets the callback proc or runs the callback proc with the current state.
  %w( pre_event event_loop error_handler ).each do |type|
    class_eval %[
      def #{type}(&blk)
        if block_given?
          @#{type} = blk
        else
          @#{type}.call(@state)
        end
      end
    ]
  end

  # Begin the polling event.
  def start_event
    pre_event
    @event_timer = EM.add_periodic_timer(interval) { event_loop }
    @timeout_timer = EM::Timer.new(timeout) do
      @event_timer.cancel
      error_handler
    end
  end

  # Helper for the event block to set notify the 
  def event_complete
    @event_timer.cancel
    @timeout_timer.cancel
  end

  private

  # Initialize default values for the event.
  def initialize_defaults
    @timeout       ||= 100
    @interval      ||= 2
    @pre_event     ||= Proc.new { |state| nil }
    @event_loop    ||= Proc.new { |state| nil }
    @error_handler ||= Proc.new { |state| nil }
  end

  # Initialize the default values for the state of the event.
  def initialize_state
    @state[:node] = @node
    @state[:interval] = interval
    @state[:timeout] = timeout
  end
end
