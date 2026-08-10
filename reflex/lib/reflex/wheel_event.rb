require 'xot/bit_flag_accessor'
require 'reflex/ext'
require 'reflex/helper'


module Reflex


  class WheelEvent < Event

    bit_flag_reader :modifiers, **MODIFIER_SYMBOLS
    private alias_method :get_modifiers!, :modifiers

    def modifiers(all: false)
      all ? get_modifiers! : (get_modifiers!.select {SHORTCUT_MODIFIER_SYMBOLS.key? _1})
    end

    def inspect()
      "#<Reflex::WheelEvent x:%p y:%p z:%p dx:%p dy:%p dz:%p mod:%p>" %
      [
        x.round(2),
        y.round(2),
        z.round(2),
        dx.round(2),
        dy.round(2),
        dz.round(2),
        modifiers(all: true)
      ]
    end

  end# WheelEvent


end# Reflex
