require 'stringio'
require 'tempfile'
require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Souffle::Log" do
  before(:each) do
    Souffle::Log.reset!
  end

  it "should ave the ability to write directly to the log" do
    io = StringIO.new
    Souffle::Log.init(io)
    Souffle::Log << "Example Log"
    io.string.should eql("Example Log")
  end

  it "should have the ability to write to a specific log level" do
    io = StringIO.new
    Souffle::Log.init(io)
    Souffle::Log.level(:info)
    Souffle::Log.info "Awesome"
    (/INFO: Awesome/ =~ io.string).should_not eql(nil)
  end
end
