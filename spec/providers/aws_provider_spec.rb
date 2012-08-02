require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Souffle::Provider::AWS" do
  include Helpers
  
  before(:each) do
    get_config
    @provider = Souffle::Provider::AWS.new
  end

  after(:each) do
    @provider = nil
  end

  # Note:
  #   All of the AWS routines will only run if you are provided a
  #   valid aws_access_key and aws_access_secret.

  it "should be able to see whether the configuration has vpc setup" do
    aws_vpc_id = "vpc-124ae13"
    aws_subnet_id = "subnet-24f6a87f"

    Souffle::Config[:aws_vpc_id] = aws_vpc_id
    Souffle::Config[:aws_subnet_id] = aws_subnet_id

    @provider.using_vpc?.should eql(true)
  end

  it "should not use vpc when the keys are missing" do
    aws_vpc_id = "vpc-124ae13"
    aws_subnet_id = "subnet-24f6a87f"

    Souffle::Config[:aws_vpc_id] = aws_vpc_id
    Souffle::Config[:aws_subnet_id] = nil
    @provider.using_vpc?.should eql(false)

    Souffle::Config[:aws_vpc_id] = nil
    Souffle::Config[:aws_subnet_id] = aws_subnet_id
    @provider.using_vpc?.should eql(false)

    Souffle::Config[:aws_vpc_id] = nil
    Souffle::Config[:aws_subnet_id] = nil
    @provider.using_vpc?.should eql(false)
  end

  it "should be able to generate a unique tag" do
    tag1 = @provider.generate_tag
    tag2 = @provider.generate_tag
    tag1.should_not eql(tag2)
  end

  it "should be able to generate a unique tag with a prefix" do
    @provider.generate_tag("example").include?("example").should eql(true)
  end
end
