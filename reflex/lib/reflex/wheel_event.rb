require 'xot/bit_flag_accessor'
require 'reflex/ext'
require 'reflex/helper'


module Reflex


  class WheelEvent < Event

    bit_flag_reader :modifiers, **MODIFIER_SYMBOLS

    def inspect()
      "#<Reflex::WheelEvent x:#{x} y:#{y} z:#{z} dx:#{dx} dy:#{dy} dz:#{dz} mod:#{modifiers}>"
    end

  end# WheelEvent


end# Reflex
