require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Souffle::Provider::AWS" do
  before(:each) do
    @provider = Souffle::Provider::AWS.new
  end

  after(:each) do
    @provider = nil
    Souffle::Config[:aws_access_key]    = ""
    Souffle::Config[:aws_access_secret] = ""
  end

  it "should have setup initialize the access key and secret" do
    junk_access_key    = "4BFAE13E2AC67BDA4B68"
    junk_access_secret = "WN3bjhS0rZu/L9+VKJd9ag/Smi8nA6/X2NkkihX+"

    Souffle::Config[:aws_access_key]    = junk_access_key
    Souffle::Config[:aws_access_secret] = junk_access_secret
    @provider.setup

    @provider.access_key.should eql(junk_access_key)
    @provider.access_secret.should eql(junk_access_secret)
  end

  it "should be able to see whether the configuration has vpc setup" do
    aws_vpc_id = "vpc-124ae13"
    aws_subnet_id = "subnet-24f6a87f"

    Souffle::Config[:aws_vpc_id] = aws_vpc_id
    Souffle::Config[:aws_subnet_id] = aws_subnet_id

    @provider.use_vpc?.should eql(true)
  end

  it "should not use vpc when the keys are missing" do
    aws_vpc_id = "vpc-124ae13"
    aws_subnet_id = "subnet-24f6a87f"

    Souffle::Config[:aws_vpc_id] = aws_vpc_id
    Souffle::Config[:aws_subnet_id] = nil
    @provider.use_vpc?.should eql(false)

    Souffle::Config[:aws_vpc_id] = nil
    Souffle::Config[:aws_subnet_id] = aws_subnet_id
    @provider.use_vpc?.should eql(false)

    Souffle::Config[:aws_vpc_id] = nil
    Souffle::Config[:aws_subnet_id] = nil
    @provider.use_vpc?.should eql(false)
  end
end
