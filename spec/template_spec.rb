require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Souffle::Template" do
  it "should generate a reasonable default template path" do
    temp_path = File.expand_path(
      File.join(File.dirname(__FILE__),
                '..', 'lib', 'souffle', 'templates'))
    Souffle::Template.template_path.should eql(temp_path)
  end

  it "should be able to generate an example template" do
    sample_binding = OpenStruct.new
    sample_binding.name = "bob"

    template = Souffle::Template.new(
      "../../../spec/templates/example_template.erb")
    template.render(sample_binding).should eql(
      "some random erb template bob\n")
  end
end
