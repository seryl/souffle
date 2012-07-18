require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Souffle::Node::RunListParser" do
  it "should be able to check whether a hash name is a valid word" do
    ex = Hash.new
    ex["name"] = "AwesomeWord"
    d = lambda { Souffle::Node::RunListParser.gaurentee_name_is_word(ex) }
    d.should_not raise_error
  end

  it "should raise an error when the hash name is spaced" do
    ex = Hash.new
    ex["name"] = "AwesomeWord SecondWord"
    d = lambda { Souffle::Node::RunListParser.gaurentee_name_is_word(ex) }
    d.should raise_error
  end

  it "should raise an error when the hash name contains invalid characters" do
    ex = Hash.new
    ex["name"] = "AwesomeWord**"
    d = lambda { Souffle::Node::RunListParser.gaurentee_name_is_word(ex) }
    d.should raise_error
  end

  it "should raise an error when the hash is empty" do
    ex = Hash.new
    d = lambda { Souffle::Node::RunListParser.gaurentee_valid_keys(ex) }
    d.should raise_error
  end

  it "should raise an error when the hash is nil" do
    ex = nil
    d = lambda { Souffle::Node::RunListParser.gaurentee_valid_keys(ex) }
    d.should raise_error
  end

  it "should raise an error when the name is nil but the type is valid" do
    ex = Hash.new
    ex["name"] = nil
    ex["type"] = "role"
    d = lambda { Souffle::Node::RunListParser.gaurentee_valid_keys(ex) }
    d.should raise_error
  end

  it "should raise an error when the name is empty but the type is valid" do
    ex = Hash.new
    ex["name"] = ""
    ex["type"] = "recipe"
    d = lambda { Souffle::Node::RunListParser.gaurentee_valid_keys(ex) }
    d.should raise_error
  end

  it "should raise an error when the name is valid but the type is nil" do
    ex = Hash.new
    ex["name"] = "best_name"
    ex["type"] = nil
    d = lambda { Souffle::Node::RunListParser.gaurentee_valid_keys(ex) }
    d.should raise_error
  end

  it "should raise an error when the name is valud but the type is empty" do
    ex = Hash.new
    ex["name"] = "anotherone"
    ex["type"] = ""
    d = lambda { Souffle::Node::RunListParser.gaurentee_valid_keys(ex) }
    d.should raise_error
  end

    it "should raise an error when parsing an invalid type" do
    d = lambda { Souffle::Node::RunListParser.parse("rofsdfsdle[somerole]") }
    d.should raise_error
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
