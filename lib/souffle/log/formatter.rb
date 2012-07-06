module Souffle
  class Log
  # Custom Log Formatter for Souffle
  class Formatter < Logger::Formatter
    @@show_time = true

    # Sets up the log formatter to show timestamps.
    #
    # @param [ true,false ] show Whether or not to show the timestamp.
    def self.show_time(show = false)
      @@show_time = show
    end

    # Prints a formatted log message.
    #
    # If Swarm::Log::Formatter.show_time == true,
    # the log message is formatted as '[time] severity: message'
    # otherwise, doesn't print the time.
    #
    # @param [ Symbol ] severity The severity of logging to use.
    # @param [ Time ] time The time to send to the log.
    # @param [ String ] progname The name/program calling the log formatter.
    # @param [ String ] msg The message to log.
    #
    # @return [ String ] The string that was logged.
    def call(severity, time, progname, msg)
      if @@show_time
        sprintf("[%s] %s: %s\n", time.rfc2822(), severity, msg2str(msg))
      else
        sprintf("%s: %s\n", severity, msg2str(msg))
      end
    end

    # Converts some argument to a Logger.severity() call to a string.
    # Regular strings pass through normally while Exceptions get formatted
    # as "message (class)\nbacktrace", and other random stuff gets
    # put through "object.inspect"
    #
    # @param [ String ] msg The message to convert to a string.
    def msg2str(msg)
      case msg
      when ::String
        msg
      when ::Exception
        "#{ msg.message } (#{ msg.class })\n" <<
          (msg.backtrace || []).join("\n")
      else
        msg.inspect
      end
    end
  end
end
