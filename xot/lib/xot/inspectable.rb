module Xot


  module Inspectable

    # Returns a string containing a human-readable representation of object.
    #
    # @return [String] inspected text
    #
    def inspect()
      "#<#{self.class.name}:0x#{(object_id << 1).to_s(16).rjust(16, '0')}>"
    end

  end# Inspectable


end# Xot
