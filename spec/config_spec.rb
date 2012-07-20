require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Souffle::Config" do
  after(:each) do
    Souffle::Config.configure { |c| c.delete(:random_something) }
    Souffle::Config[:aws_access_key] = ""
    Souffle::Config[:aws_access_secret] = ""
  end

  it "should be able to read from a ruby config file" do
    config = File.join(File.dirname(__FILE__), 'config', 'example.rb')
    Souffle::Config.from_file(config)

    Souffle::Config[:random_something].should == 1234
    Souffle::Config[:aws_access_key].should == "test_key"
    Souffle::Config[:aws_access_secret].should == "test_secret"
  end

  it "should be able to read from a json config stream" do
    config = File.join(File.dirname(__FILE__), 'config', 'example.json')
    Souffle::Config.from_stream_json(IO.read(config))

    Souffle::Config[:random_something].should == 1234
    Souffle::Config[:aws_access_key].should == "test_key"
    Souffle::Config[:aws_access_secret].should == "test_secret"
  end

  it "should be able to read from a json config file" do
    config = File.join(File.dirname(__FILE__), 'config', 'example.json')
    Souffle::Config.from_file(config, "json")

    Souffle::Config[:random_something].should == 1234
    Souffle::Config[:aws_access_key].should == "test_key"
    Souffle::Config[:aws_access_secret].should == "test_secret"
  end
end
