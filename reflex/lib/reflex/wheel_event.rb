# -*- coding: utf-8 -*-


require 'reflex/ext'


module Reflex


  class WheelEvent < Event

    def inspect()
      "#<Reflex::WheelEvent x:#{x} y:#{y} z:#{z} dx:#{dx} dy:#{dy} dz:#{dz} mod:#{modifiers}>"
    end

  end# WheelEvent


end# Reflex
