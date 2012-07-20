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
      @original_item = item
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

    # Returns the RunListItem as it's original string.
    def to_s
      @original_item
    end

    # Overriding the default equality comparator to use string representation.
    # 
    # @param [ Souffle::Node::RunListItem ] runlist_item
    # 
    # @return [ true,false ] Whether or not the objects are equal.
    def ==(runlist_item)
      self.to_s == runlist_item.to_s
    end

    # Overriding the default equality comparator to use string representation.
    # 
    # @param [ Souffle::Node::RunListItem ] runlist_item
    # 
    # @return [ true,false ] Whether or not the objects are equal.
    def eql?(runlist_item)
      self.to_s == runlist_item.to_s
    end
  end
end
