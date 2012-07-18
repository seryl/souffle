require 'souffle/node/runlist_parser'

module Souffle
  # A single runlist item, most be parsed and either a recipe or role.
  class Node::RunListItem

    # Creates a new runlist item from a string.
    # 
    # @param [ String ] item The runlist string to turn into an object.
    # @raise [ InvalidRunlistName, InvalidRunlistType ] Raises exceptions when
    # the runlist item or type isn't a proper chef role or recipe.
    def initialize(item=nil)
      @item = Souffle::Node::RunListParser.parse(item)
    end

    # Returns the name of the runlist item.
    # 
    # @return [ String ] The name of the runlist item.
    def name
      @item["name"]
    end

    # Returns the type of the runlist item.
    # 
    # @return [ String ] The type of the runlist item.
    def type
      @item["type"]
    end
  end
end
