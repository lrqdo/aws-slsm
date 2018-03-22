# frozen_string_literal: true

# Manage aws-slsm PID execution
class Pid
  attr_reader :pidfile

  def initialize(pidfile)
    @pidfile = pidfile
  end

  def write
    File.open(@pidfile, ::File::CREAT | ::File::EXCL | ::File::WRONLY) do |f|
      f.write(Process.pid)
    end
    at_exit do
      File.delete(@pidfile) if File.exist?(@pidfile)
    end
  rescue Errno::EEXIST
    check
    retry
  end

  def check
    case status
    when :running, :not_owned
      puts "A server is already running. Check #{@pidfile}"
      exit(1)
    when :dead
      File.delete(@pidfile)
    end
  end

  def status
    return :exited unless File.exist?(@pidfile)
    pid = ::File.read(@pidfile).to_i
    return :dead if pid.zero?
    Process.kill(0, pid) # check process status
    :running
  rescue Errno::ESRCH
    :dead
  rescue Errno::EPERM
    :not_owned
  end
end
