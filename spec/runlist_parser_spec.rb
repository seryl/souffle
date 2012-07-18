require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Souffle::Node::RunListParser" do
  it "should be able to check whether a hash name is a valid word" do
    ex = Hash.new
    ex["name"] = "AwesomeWord"
    Souffle::Node::RunListParser.name_is_word(ex).should eql(true)
  end

  it "should return false when the hash name is spaced" do
    ex = Hash.new
    ex["name"] = "AwesomeWord SecondWord"
    Souffle::Node::RunListParser.name_is_word(ex).should eql(false)
  end

  it "should return false when the hash name contains invalid characters" do
    ex = Hash.new
    ex["name"] = "AwesomeWord**"
    Souffle::Node::RunListParser.name_is_word(ex).should eql(false)
  end

  it "should be invalid when the hash is empty" do
    ex = Hash.new
    Souffle::Node::RunListParser.is_valid(ex).should eql(false)
  end

  it "should be invalid when the hash is nil" do
    ex = nil
    Souffle::Node::RunListParser.is_valid(ex).should eql(false)
  end

  it "should be invalid when the name is nil but the type is valid" do
    ex = Hash.new
    ex["name"] = nil
    ex["type"] = "role"
    Souffle::Node::RunListParser.is_valid(ex).should eql(false)
  end

  it "should be invalid when the name is empty but the type is valid" do
    ex = Hash.new
    ex["name"] = ""
    ex["type"] = "recipe"
    Souffle::Node::RunListParser.is_valid(ex).should eql(false)
  end

  it "should be invalid when the name is valid but the type is nil" do
    ex = Hash.new
    ex["name"] = "best_name"
    ex["type"] = nil
    Souffle::Node::RunListParser.is_valid(ex).should eql(false)
  end

  it "should be invalid when the name is valud but the type is empty" do
    ex = Hash.new
    ex["name"] = "anotherone"
    ex["type"] = ""
    Souffle::Node::RunListParser.is_valid(ex).should eql(false)
  end

  it "should be able to parse a role" do
    r = Souffle::Node::RunListParser.parse("role[painfully_long_role]")
    r.should eql( {"type" => "role", "name" => "painfully_long_role"} )
  end

  it "should be able to parse a recipe" do
    r = Souffle::Node::RunListParser.parse("recipe[a_pretty_serious_recipe]")
    r.should eql( {"type" => "recipe", "name" => "a_pretty_serious_recipe"} )
  end
end
