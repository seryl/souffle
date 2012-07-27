require 'souffle/node/runlist_item'

# A specialized Array that handles runlist items appropriately.
class Souffle::Node::RunList < Array

  # Pushes another runlist item onto the runlist array.
  # 
  # @param [ String ] item The runlist item as a string.
  def <<(item)
    item = Souffle::Node::RunListItem.new(item)
    super(item)
  end

  # Pushes another item onto the runlist array.
  # 
  # @param [ String ] item The runlist item as a string.
  def push(item)
    item = Souffle::Node::RunListItem.new(item)
    super(item)
  end

end
