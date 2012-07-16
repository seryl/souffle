# The souffle worker command line parser.
class SouffleWorker < Thor

  # Starts up the souffle worker.
  desc "start", "Starts up the worker."
  def start
    Souffle::Worker.new.run
  end
end
