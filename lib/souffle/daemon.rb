require 'etc'

# Daemon helper routines.
class Souffle::Daemon
  class << self
    attr_accessor :name

    # Daemonize the current process, managing pidfiles and process uid/gid.
    #
    # @param [ String ] name The name to be used for the pid file
    def daemonize(name)
      @name = name
      pid = pid_from_file
      unless running?
        remove_pid_file()
        Souffle::Log.info("Daemonizing...")
        begin
          exit if fork; Process.setsid; exit if fork
          msg =  "Forked, in #{Process.pid}. "
          msg << "Privileges: #{Process.euid} #{Process.egid}"
          Souffle::Log.info(msg)
          File.umask Souffle::Config[:umask]
          $stdin.reopen("/dev/null")
          $stdout.reopen("/dev/null", "a")
          $stderr.reopen($stdout)
          save_pid_file;
          at_exit { remove_pid_file }
        rescue NotImplementedError => e
          Souffle::Application.fatal!("There is no fork: #{e.message}")
        end
      else
        Souffle::Application.fatal!("Souffle is already running pid #{pid}")
      end
    end

    # Checks if Souffle is running based on the pid_file.
    # 
    # @return [ true,false ] Whether or not Souffle is running.
    def running?
      if pid_from_file.nil?
        false
      else
        Process.kill(0, pid_from_file)
        true
      end
    rescue Errno::ESRCH, Errno::ENOENT
      false
    rescue Errno::EACCES => e
      msg =  "You don't have access to the PID "
      msg << "file at #{pid_file}: #{e.message}"
      Souffle::Application.fatal!(msg)
    end
    
    # Gets the pid file for @name.
    # 
    # @return [ String ] Location of the pid file for @name.
    def pid_file
       Souffle::Config[:pid_file] or "/tmp/#{@name}.pid"
    end
    
    # Sucks the pid out of pid_file.
    # 
    # @return [ Integer,nil ] The PID from pid_file or nil if it doesn't exist.
    def pid_from_file
      File.read(pid_file).chomp.to_i
    rescue Errno::ENOENT, Errno::EACCES
      nil
    end
  
    # Store the PID on the filesystem.
    # 
    # @note
    #   This uses the Souffle::Config[:pid_file] option or "/tmp/name.pid"
    #   by default.
    def save_pid_file
      file = pid_file
      begin
        FileUtils.mkdir_p(File.dirname(file))
      rescue Errno::EACCES => e
        msg =  "Failed store pid in #{File.dirname(file)}, "
        msg << "permission denied: #{e.message}"
        Souffle::Application.fatal!(msg)
      end
    
      begin
        File.open(file, "w") { |f| f.write(Process.pid.to_s) }
      rescue Errno::EACCES => e
        msg =  "Couldn't write to pidfile #{file}, "
        msg << "permission denied: #{e.message}"
        Souffle::Application.fatal!(msg)
      end
    end
  
    # Delete the PID from the filesystem
    def remove_pid_file
      FileUtils.rm(pid_file) if File.exists?(pid_file)
    end
         
    # Change process user/group to those specified in Souffle::Config
    def change_privilege
      Dir.chdir("/")

      msg =  "About to change privilege to "
      if Souffle::Config[:user] and Souffle::Config[:group]
        msg << "#{Souffle::Config[:user]}:#{Souffle::Config[:group]}"
        Souffle::Log.info(msg)
        _change_privilege(Souffle::Config[:user], Souffle::Config[:group])
      elsif Souffle::Config[:user]
        msg << "#{Souffle::Config[:user]}"
        Souffle::Log.info(msg)
        _change_privilege(Souffle::Config[:user])
      end
    end
  
    # Change privileges of the process to be the specified user and group
    # 
    # @param [ String ] user The user to change the process to.
    # @param [ String ] group The group to change the process to.
    # 
    # @note
    #   The group parameter defaults to user unless specified.
    def _change_privilege(user, group=user)
      uid, gid = Process.euid, Process.egid

      begin
        target_uid = Etc.getpwnam(user).uid
      rescue ArgumentError => e
        msg =  "Failed to get UID for user #{user}, does it exist? "
        msg << e.message
        Souffle::Application.fatal!(msg)
        return false
      end
 
      begin
        target_gid = Etc.getgrnam(group).gid
      rescue ArgumentError => e
        msg =  "Failed to get GID for group #{group}, does it exist? "
        msg << e.message
        Souffle::Application.fatal!(msg)
        return false
      end
    
      if (uid != target_uid) or (gid != target_gid)
        Process.initgroups(user, target_gid)
        Process::GID.change_privilege(target_gid)
        Process::UID.change_privilege(target_uid)
      end
      true
    rescue Errno::EPERM => e
      msg =  "Permission denied when trying to change #{uid}:#{gid} "
      msg << "to #{target_uid}:#{target_gid}. #{e.message}"
      Souffle::Application.fatal!(msg)
    end
  end
end
