require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Souffle::Config" do
  after(:each) do
    Souffle::Config.configure { |c| c.delete(:random_something) }
    Souffle::Config[:aws_access_key] = ""
    Souffle::Config[:aws_access_secret] = ""
  end

  it "should have default values for aws, rack and vagrant" do
    %w{ aws_access_key aws_access_secret
      rack_host rack_port rack_environment vagrant_dir }.each do |cfg|
        cfg = cfg.to_sym
        Souffle::Config.configuration.keys.include?(cfg).should eql(true)
      end
  end

  it "should have a proper default vagrant directory" do
    vagrant_dir = "#{ENV['HOME']}/vagrant/vms"
    Souffle::Config[:vagrant_dir].should eql(vagrant_dir)
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
