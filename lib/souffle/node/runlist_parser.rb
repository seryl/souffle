module Souffle
  # The runlist parser singleton.
  class Node::RunListParser

    # The runlist match parser
    PARSER = %r{
      (?<type> (recipe|role)) {0}   # The runlist item type.
      (?<name> (.*)) {0}            # The runlist item name.

      \g<type>\[\g<name>\]
    }x

    class << self
      # Checks to see whether the runlist item is a valid recipe or role.
      # 
      # @param [ String ] item The runlist item.
      # 
      # @return [ Hash ] The runlist item as a hash.
      def parse(item)
        runlist_hash = hashify_match(PARSER.match(item))
        runlist_hash if is_valid(runlist_hash)
      end

      # Takes the matches and converts them into a hashed version.
      # 
      # @param [ MatchData,nil ] match The MatchData to hashify.
      # 
      # @return [ Hash,nil ] The hashified version of the runlist item.
      def hashify_match(match)
        return nil if match.nil?
        Hash[*match.names.zip(match.captures).flatten]
      end

      # Checks whether or not the runlist item is valid.
      # 
      # @param [ Hash, nil ] runlist_hash The runlist item to check.
      # 
      # @return [ true,false ] Wehther or not the given runlist item is valid.
      def is_valid(runlist_hash)
        return false if runlist_hash.nil?
        valid_keys(runlist_hash) && name_is_word(runlist_hash)
      end

      # Tests whether the runlist_hash name and type are valid.
      # 
      # @param [ Hash ] runlist_hash The runlist hash to test.
      # 
      # @return [ true,false ] Whether or not the keys are valid.
      def valid_keys(runlist_hash)
            runlist_hash["name"] != nil and runlist_hash["name"] != "" \
        and runlist_hash["type"] != nil and runlist_hash["type"] != ""
      end

      # Checks whether the runlist_hash is a valid word.
      # 
      # @param [ Hash ] runlist_hash The runlist hash to test.
      # 
      # @return [ true,false ] Whether or not the runlist name is a word.
      def name_is_word(runlist_hash)
        (/\w+/).match(runlist_hash["name"])[0] == runlist_hash["name"]
      rescue
        false
      end
    end

  end
end
