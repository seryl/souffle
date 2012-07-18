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
        gaurentee_valid_keys(runlist_hash)
        gaurentee_name_is_word(runlist_hash)
        runlist_hash
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

      # Tests whether the runlist_hash name and type are valid.
      # 
      # @param [ Hash ] runlist_hash The runlist hash to test.
      # 
      # @raise [ InvalidRunlistName, InvalidRunlistType ] Raises exceptions
      # when the runlist match failed, the type wasn't a recipe or role,
      # or when the name itself isn't a valid word.
      def gaurentee_valid_keys(runlist_hash)
        if runlist_hash.nil?
          raise Souffle::Exceptions::InvalidRunlistType,
            "Type must be one of (role|recipe)"
        end
        if runlist_hash["name"].nil? or runlist_hash["name"].empty?
          raise Souffle::Exceptions::InvalidRunlistName,
            "Name cannot be nil or empty."
        end
        if runlist_hash["type"].nil? or runlist_hash["type"].empty?
          raise Souffle::Exceptions::InvalidRunlistType,
            "Type cannot be nil or empty and must be one of (role|recipe)"
        end
      end

      # Checks whether the runlist_hash is a valid word.
      # 
      # @param [ Hash ] runlist_hash The runlist hash to test.
      # 
      # @raise [ InvalidRunlistName ] Runlist Name is invalid.
      def gaurentee_name_is_word(runlist_hash)
        unless (/\w+/).match(runlist_hash["name"])[0] == runlist_hash["name"]
          raise Souffle::Exceptions::InvalidRunlistName,
            "Name must be [A-Za-z0-9_]."
        end
      end
    end

  end
end
