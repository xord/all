require 'xot/bit_flag_accessor'
require 'reflex/ext'
require 'reflex/helper'


module Reflex


  class WheelEvent < Event

    bit_flag_reader :modifiers, **MODIFIER_SYMBOLS
    private alias_method :get_modifiers!, :modifiers

    def modifiers(locks: true)
      locks ? get_modifiers! : (get_modifiers! - LOCK_MODIFIER_SYMBOLS.keys)
    end

    def inspect()
      "#<Reflex::WheelEvent x:#{x} y:#{y} z:#{z} dx:#{dx} dy:#{dy} dz:#{dz} mod:#{modifiers}>"
    end

  end# WheelEvent


end# Reflex
