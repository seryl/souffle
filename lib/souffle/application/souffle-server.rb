require 'souffle/application'

# The server command line parser.
class Souffle::Application::Server < Souffle::Application

    def run
      trap("INT") { exit 0 }
      begin parse_options
      rescue
        self.opt_parser.help
        exit 0
      end
      run_commands
    end

    def aliases(cmd)
      DEFAULT_ALIASES.each { |k, v| return k if v.include?(cmd) }
      nil
    end

    def run_commands
      if ARGV.size == 0 || aliases(ARGV.first).nil?
        puts self.opt_parser.help
        exit 0
      else
        send(aliases(ARGV.first).to_sym)
      end
    end

  end
end
