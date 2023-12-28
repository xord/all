require 'rays/ext'


module Rays


  class Font

    include Comparable

    alias w width
    alias h height

    def <=>(o)
      ret = name <=> o.name; return ret if ret != 0
            size <=> o.size
    end

    def inspect()
      "#<Rays::Font name='#{name}', size=#{size}>"
    end

  end# Font


end# Rays
