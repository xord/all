require 'rays/ext'


module Rays


  class ColorSpace

    include Comparable

    def <=>(o)
      type <=> o.type
    end

    def hash()
      type.hash
    end

    def eql?(o)
      self == o
    end

    def inspect()
      "#<#{self.class.name} #{to_s}>"
    end

  end# Color


end# Rays
