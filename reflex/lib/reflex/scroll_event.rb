require 'reflex/ext'


module Reflex


  class ScrollEvent < Event

    def inspect()
      "#<Reflex::ScrollEvent x:#{x} y:#{y} z:#{z} dx:#{dx} dy:#{dy} dz:#{dz}>"
    end

  end# ScrollEvent


end# Reflex
