require 'erb'
require 'tilt'

module Souffle
  # Template wrapper around the Tilt Template Abstraction Library.
  class Template

    # Creates a new template.
    # 
    # @param [ String ] template The name of the template to render.
    def initialize(template)
      @template = Tilt.new(
        File.expand_path("#{Souffle::Template.template_path}/#{template}"))
    end

    # Renders the template with the given binding.
    # 
    # @param [ Object ] binding The binding object for the template.
    # 
    # @return [ String ] The rendered template.
    def render(binding)
      @template.render(binding)
    end

    # Helper pointing to the default templates path.
    # 
    # @return [ String ] The path to the Souffle templates.
    def self.template_path
      File.expand_path(File.join(File.dirname(__FILE__), 'templates'))
    end

  end
end
